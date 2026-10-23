#!/usr/bin/env bash
# Ripristina un backup verificato nel DB LOCALE (sovrascrive $DB_NAME).
#   restore-db.sh FILE [--dry-run] --confirm
# In PROD il DB non cambia con la migrazione: se servisse, lo importa l'utente (phpMyAdmin).
source "$(dirname "$0")/lib.sh"

FILE=""; DRY=0; OK=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --confirm) OK=1 ;;
    -*) die "argomento sconosciuto: $1" ;;
    *) FILE=$1 ;;
  esac; shift
done
banner LOCAL
[ -f "$FILE" ] || die "file non trovato: ${FILE:-<vuoto>}"
[ -f "$FILE.verified" ] || die "backup non verificato: esegui prima backup-db.sh --verify $FILE"
[ "$(sha256sum "$FILE" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$FILE.verified")" ] || die "SHA-256 diverso da quello verificato: file modificato?"

info "ripristino $FILE -> $DB_NAME (sovrascrive il DB locale)"
[ $DRY = 1 ] && { echo "(dry-run) nessuna modifica"; exit 0; }
[ $OK = 1 ] || die "manca --confirm"

M="$MYSQL_BIN/mysql.exe"
"$M" "${DB_ARGS[@]}" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8 COLLATE utf8_general_ci"
case "$FILE" in *.gz) gzip -dc "$FILE" ;; *) cat "$FILE" ;; esac | "$M" "${DB_ARGS[@]}" --default-character-set=utf8 "$DB_NAME"
info "OK: $DB_NAME ripristinato"
