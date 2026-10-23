#!/usr/bin/env bash
# Backup del DB con verifica di ripristino.
#   backup-db.sh [--dry-run]                 dump del DB locale + verifica
#   backup-db.sh --verify FILE [--dry-run]   verifica un dump esistente (es. quello di PROD da prod-to-local)
# La verifica importa il dump in $DB_VERIFY e confronta tabelle (e righe, per il DB locale); se passa scrive FILE.verified.
source "$(dirname "$0")/lib.sh"

DRY=0; FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --verify)  FILE=${2:?--verify vuole un file}; shift ;;
    *) die "argomento sconosciuto: $1" ;;
  esac; shift
done
banner LOCAL
[ -x "$MYSQL_BIN/mysql.exe" ] || die "mysql non trovato in $MYSQL_BIN (MYSQL_VERSION/MYSQL_BIN in config.sh)"
mkdir -p "$OUT/backup"
M="$MYSQL_BIN/mysql.exe"
"$M" "${DB_ARGS[@]}" -N -e 'SELECT 1' > /dev/null 2>&1 || die "MySQL locale non raggiungibile: avvia i servizi di Dunebox"

if [ -z "$FILE" ]; then
  FILE="$OUT/backup/$DB_NAME-$(date +%Y%m%d-%H%M%S).sql.gz"
  info "dump di $DB_NAME -> $FILE"
  [ $DRY = 1 ] && { echo "(dry-run) nessun dump eseguito"; exit 0; }
  "$MYSQL_BIN/mysqldump.exe" "${DB_ARGS[@]}" --single-transaction --routines --triggers --hex-blob \
    --default-character-set=utf8 "$DB_NAME" | gzip > "$FILE"
  SOURCE_DB=$DB_NAME
else
  [ -f "$FILE" ] || die "file non trovato: $FILE"
  SOURCE_DB=""
fi

cat_dump() { case "$FILE" in *.gz) gzip -dc "$FILE" ;; *) cat "$FILE" ;; esac; }
gzip -t "$FILE" 2>/dev/null || [[ "$FILE" != *.gz ]] || die "archivio gzip corrotto: $FILE"
dump_tables=$(cat_dump | grep -c '^CREATE TABLE' || true)
[ "$dump_tables" -gt 0 ] || die "il dump non contiene tabelle: $FILE"
info "tabelle nel dump: $dump_tables"
[ $DRY = 1 ] && { echo "(dry-run) verifica di ripristino non eseguita"; exit 0; }

info "ripristino di prova in $DB_VERIFY"
"$M" "${DB_ARGS[@]}" -e "DROP DATABASE IF EXISTS \`$DB_VERIFY\`; CREATE DATABASE \`$DB_VERIFY\` CHARACTER SET utf8 COLLATE utf8_general_ci"
cat_dump | "$M" "${DB_ARGS[@]}" --default-character-set=utf8 "$DB_VERIFY" || die "il ripristino di prova è fallito"

sql() { "$M" "${DB_ARGS[@]}" -N -e "$1" | tr -d '\r'; }   # mysql.exe di Windows chiude le righe con \r\n
counts() { # "tabella righe" per ogni tabella, con una sola query: se una tabella non si legge, fallisce tutto
  local q
  q=$(sql "SET SESSION group_concat_max_len=1000000; SELECT GROUP_CONCAT(CONCAT('SELECT ''', table_name, ''', COUNT(*) FROM \`$1\`.\`', table_name, '\`') SEPARATOR ' UNION ALL ') FROM information_schema.tables WHERE table_schema='$1' AND table_type='BASE TABLE'")
  [ -n "$q" ] && [ "$q" != NULL ] || return 1
  printf '%s;' "$q" | "$M" "${DB_ARGS[@]}" -N | tr -d '\r' | sort   # stdin: la query è troppo lunga per la riga di comando
}
restored_tables=$(sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_VERIFY' AND table_type='BASE TABLE'")
[ "$restored_tables" = "$dump_tables" ] || die "tabelle ripristinate $restored_tables != tabelle nel dump $dump_tables"
if [ -n "$SOURCE_DB" ]; then
  counts "$SOURCE_DB" > "$OUT/counts-src.tmp" || die "conteggio righe fallito su $SOURCE_DB"
  counts "$DB_VERIFY" > "$OUT/counts-verify.tmp" || die "conteggio righe fallito su $DB_VERIFY"
  [ "$(wc -l < "$OUT/counts-src.tmp")" = "$dump_tables" ] || die "conteggio incompleto su $SOURCE_DB"
  diff -q "$OUT/counts-src.tmp" "$OUT/counts-verify.tmp" > /dev/null || die "il numero di righe del ripristino non coincide con $SOURCE_DB"
  info "righe per tabella identiche a $SOURCE_DB ($(awk '{s+=$2} END {print s}' "$OUT/counts-src.tmp") righe)"
  rm -f "$OUT"/counts-*.tmp
fi
"$M" "${DB_ARGS[@]}" -e "DROP DATABASE \`$DB_VERIFY\`"

sha=$(sha256sum "$FILE" | cut -d' ' -f1)
echo "$sha  $(basename "$FILE")  tables=$dump_tables  verified=$(date -Iseconds)" > "$FILE.verified"
info "OK: backup verificato -> $FILE.verified"
