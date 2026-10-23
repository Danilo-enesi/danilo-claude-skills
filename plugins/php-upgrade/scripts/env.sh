#!/usr/bin/env bash
# Rileva l'ambiente: versioni PHP/MySQL, estensioni, ini del web server locale e di PROD. Sola lettura.
#   env.sh
source "$(dirname "$0")/lib.sh"
require_local
banner LOCAL

host_php=$(grep -oE '"php": *"[0-9.]+"' "$ROOT/.dunebox/config.json" 2>/dev/null | grep -oE '[0-9.]+"$' | tr -d '"' || true)
info "PHP dell'host locale (.dunebox/config.json): ${host_php:-?}   PROD oggi: $PHP_PROD   arrivo: $PHP_TO"
info "PHP CLI: $("$PHP_FROM_BIN" -r 'echo PHP_VERSION;') / $("$PHP_TO_BIN" -r 'echo PHP_VERSION;')"
info "MySQL locale: $("$MYSQL_BIN/mysql.exe" "${DB_ARGS[@]}" -N -e 'SELECT VERSION()' 2>/dev/null || echo 'NON RAGGIUNGIBILE (servizi Dunebox fermi?)')"
info "Git: $(git -C "$ROOT" log -1 --format='%h %s') $(git -C "$ROOT" rev-parse -q --verify "$BASE_TAG" >/dev/null && echo "(tag $BASE_TAG presente)" || echo "(manca il tag $BASE_TAG)")"

need_ext="mysqli mbstring gd curl json openssl iconv xml zlib"
"$PHP_TO_BIN" -m > "$OUT/local-php-modules.txt"
missing=""
for e in $need_ext; do grep -qix "$e" "$OUT/local-php-modules.txt" || missing="$missing $e"; done
info "Estensioni richieste mancanti in PHP $PHP_TO locale (CLI):${missing:- nessuna}"
"$PHP_TO_BIN" --ini | grep -q 'Loaded Configuration File: *(none)' &&
  warn "il PHP $PHP_TO CLI non ha php.ini: crealo con SOLO extension_dir (assoluto) + extension=…, il resto ai default (non da php.ini-development: mette short_open_tag=Off)"

ini_val() { grep -iE "^\s*$1\s*=" "$2" | tail -1 | cut -d= -f2 | tr -d ' \r"' | tr 'A-Z' 'a-z'; }
uses_short=$(grep -rlE '<\?(\s|$)' --include=*.php --include=*.inc "${SITE_PATHS[@]/#/$ROOT/}" 2>/dev/null | wc -l || true)
if [ -f "$WEB_INI" ]; then
  sot=$(ini_val short_open_tag "$WEB_INI"); de=$(ini_val display_errors "$WEB_INI")
  info "ini web ($WEB_INI): short_open_tag=${sot:-?} display_errors=${de:-?}   (file del sito con '<?': $uses_short)"
  [ "$uses_short" = 0 ] || [ "$sot" = on ] || [ "$sot" = 1 ] || warn "short_open_tag non è On nell'ini web: il sito usa <?, il front darà 500"
else
  warn "ini web non trovato: $WEB_INI (imposta WEB_INI in config.sh)"
fi

# PROD (passo P0: file creati dall'utente con ssh)
pm="$MIG_DIR/prod-php${PHP_TO//./}-modules.txt"; pi="$MIG_DIR/prod-php${PHP_TO//./}-ini.txt"
if [ -f "$pm" ]; then
  file "$pm" | grep -q UTF-16 && warn "$pm è UTF-16 (redirezione > di PowerShell): rifallo con | Out-File -Encoding ascii"
  miss=""; for e in $need_ext; do grep -qix "$e" "$pm" || miss="$miss $e"; done
  info "Estensioni richieste mancanti in PROD:${miss:- nessuna}"
else
  warn "manca $(basename "$pm"): estensioni di PROD non verificate (passo P0)"
fi
if [ -f "$pi" ]; then
  info "ini di PROD: $(tr -d '\r' < "$pi" | paste -sd' ')"
  [ "$uses_short" = 0 ] || grep -qiE '^short_open_tag => On' "$pi" || warn "in PROD short_open_tag non è On: impostarlo (cPanel › MultiPHP INI Editor) PRIMA del cambio versione"
  grep -qiE '^display_errors => (Off|0|stderr)' "$pi" || warn "in PROD display_errors non è Off: i Warning comparirebbero nelle pagine"
else
  warn "manca $(basename "$pi"): short_open_tag/display_errors di PROD non verificati (passo P0)"
fi
