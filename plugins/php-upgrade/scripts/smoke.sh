#!/usr/bin/env bash
# Prova in esecuzione: visita le URL e i PDF e controlla stato HTTP, errori nella pagina e log PHP.
#   smoke.sh --target local [--record]          LOCAL; --record salva gli stati attuali come riferimento (sito ancora sul PHP vecchio)
#   smoke.sh --target local --admin-cookie 'NOME=VALORE'   in più i moduli dell'admin (urls-admin.txt, solo GET, sessione dell'utente)
#   smoke.sh --target prod --confirm-prod       PROD, solo richieste GET
# Liste in _migration/: urls.txt, urls-pdf.txt, urls-admin.txt; riferimento in baseline-status.txt.
# FAIL (exit 1): stato HTTP diverso dal riferimento, PDF che non è un PDF, Fatal/Parse/Uncaught (pagina o log).
# WARN (exit 0): Warning PHP; li valuta la skill mig-fix-runtime-error.
source "$(dirname "$0")/lib.sh"

TARGET=""; RECORD=0; CONFIRM=0; COOKIE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET=${2:-}; shift ;;
    --record) RECORD=1 ;;
    --confirm-prod) CONFIRM=1 ;;
    --admin-cookie) COOKIE=${2:-}; shift ;;
    *) die "argomento sconosciuto: $1" ;;
  esac; shift
done
case "$TARGET" in
  local) BASE=$LOCAL_URL; banner LOCAL ;;
  prod)  BASE=$PROD_URL; banner PROD
         [ $CONFIRM = 1 ] || die "in PROD serve --confirm-prod (solo dopo l'ok esplicito dell'utente)"
         [ $RECORD = 0 ] || die "--record solo in LOCAL"
         [ -z "$COOKIE" ] || die "--admin-cookie solo in LOCAL" ;;
  *) die "uso: smoke.sh --target local|prod" ;;
esac

REF="$MIG_DIR/baseline-status.txt"
[ $RECORD = 1 ] || [ -f "$REF" ] || die "manca $REF: eseguilo prima con --target local --record sul sito ancora sul PHP vecchio"
REPORT="$OUT/smoke-$TARGET-$(date +%Y%m%d-%H%M%S).txt"
LOG=""
if [ "$TARGET" = local ]; then
  v=$(grep -oE '"php": *"[0-9.]+"' "$ROOT/.dunebox/config.json" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "$PHP_TO")
  LOG="$PHP_LOG_DIR/php_errors-$v.log"
  touch "$LOG"; log_start=$(wc -l < "$LOG")
  info "PHP dell'host: $v  log: $LOG"
fi

fails=0; warns=0; n=0
fetch() { curl -sk -m 120 ${COOKIE:+-b "$COOKIE"} -o "$OUT/page.tmp" -w '%{http_code} %{content_type}' "$BASE$1" || echo "000 -"; }
check_body() {
  if grep -aqiE '(fatal error|parse error|uncaught)' "$OUT/page.tmp"; then
    echo "FAIL $1 errore PHP nella pagina: $(grep -aoiE '(fatal error|parse error|uncaught)[^<]{0,150}' "$OUT/page.tmp" | head -1)" >> "$REPORT"; fails=$((fails+1))
  elif grep -aqE '<b>(Warning|Deprecated)</b>:' "$OUT/page.tmp"; then
    echo "WARN $1 $(grep -aoE '<b>(Warning|Deprecated)</b>:[^<]{0,150}' "$OUT/page.tmp" | head -1)" >> "$REPORT"; warns=$((warns+1))
  fi
}

: > "$REPORT"
[ $RECORD = 1 ] && : > "$REF"
while read -r u; do
  n=$((n+1))
  read -r code ctype <<< "$(COOKIE= fetch "$u")"
  if [ $RECORD = 1 ]; then echo "$u $code" >> "$REF"; continue; fi
  expected=$(awk -v u="$u" '$1==u {print $2; exit}' "$REF")
  [ "$code" = "$expected" ] || { echo "FAIL $u HTTP $code (riferimento ${expected:-nessuno})" >> "$REPORT"; fails=$((fails+1)); }
  check_body "$u"
done < <(list_file "$MIG_DIR/urls.txt")

if [ $RECORD = 0 ]; then
  while read -r u; do
    n=$((n+1))
    read -r code ctype <<< "$(COOKIE= fetch "$u")"
    if [ "$code" != 200 ] || [ "$(head -c 5 "$OUT/page.tmp")" != "%PDF-" ]; then
      echo "FAIL $u PDF non generato (HTTP $code, $ctype)" >> "$REPORT"; fails=$((fails+1)); check_body "$u"
    fi
  done < <(list_file "$MIG_DIR/urls-pdf.txt")
fi

# Admin: senza riferimento (serve login); atteso 200 e nessun errore. 302 = sessione scaduta/non valida.
if [ -n "$COOKIE" ] && [ $RECORD = 0 ]; then
  while read -r u; do
    n=$((n+1))
    read -r code ctype <<< "$(fetch "$u")"
    [ "$code" = 302 ] && die "admin: redirect al login su $u, il cookie non è valido o la sessione è scaduta"
    [ "$code" = 200 ] || { echo "FAIL $u HTTP $code (admin, atteso 200)" >> "$REPORT"; fails=$((fails+1)); }
    check_body "$u"
  done < <(list_file "$MIG_DIR/urls-admin.txt")
fi
rm -f "$OUT/page.tmp"

if [ -n "$LOG" ]; then
  # solo righe del progetto; contano anche le azioni fatte dall'utente nel browser durante lo smoke
  tail -n +$((log_start+1)) "$LOG" | grep -aF "$(basename "$ROOT")" | sed -E 's/^\[[^]]*\] //' | sort | uniq -c | sort -rn > "$OUT/log.tmp" || true
  while read -r cnt line; do
    case "$line" in
      *"Fatal error"*|*"Parse error"*|*Uncaught*) echo "FAIL log x$cnt $line" >> "$REPORT"; fails=$((fails+1)) ;;
      *Warning*) echo "WARN log x$cnt $line" >> "$REPORT"; warns=$((warns+1)) ;;
    esac
  done < "$OUT/log.tmp"
  rm -f "$OUT/log.tmp"
fi

if [ $RECORD = 1 ]; then info "riferimento salvato: $n URL -> $REF"; exit 0; fi
info "$n richieste: $fails FAIL, $warns WARN  -> $REPORT"
grep -m 15 '^FAIL' "$REPORT" || true
[ $fails = 0 ]
