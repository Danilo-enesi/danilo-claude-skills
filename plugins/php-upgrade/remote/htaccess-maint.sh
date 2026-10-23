#!/usr/bin/env bash
# Modo manutenzione nel .htaccess: SOLO aggiunge un blocco tra marcatori e SOLO toglie quel blocco.
#   htaccess-maint.sh on     HTACCESS STATEDIR PAGE IP [IP...]
#   htaccess-maint.sh off    HTACCESS STATEDIR
#   htaccess-maint.sh status HTACCESS STATEDIR
# on : inserisce il blocco subito dopo la prima riga "RewriteEngine On" (stesso rientro, stessi fine riga).
#      Salva in STATEDIR la copia del .htaccess e il blocco esatto; verifica che togliendo il blocco resti
#      byte per byte il file di partenza. Se il blocco c'è già con gli stessi IP non fa nulla.
# off: toglie le righe tra i marcatori SOLO se sono identiche al blocco salvato; verifica che sia cambiato solo quello.
# Nessuna altra riga del file viene mai toccata. Gira sul server (bash, coreutils) e nei test in locale.
set -euo pipefail
die() { echo "ERRORE: $*" >&2; exit 1; }
BEGIN='# >>> php-upgrade manutenzione (righe aggiunte da php-upgrade: non modificare) >>>'
END='# <<< php-upgrade manutenzione <<<'

cmd=${1:-}; F=${2:-}; S=${3:-}
[ -n "$cmd" ] && [ -n "$F" ] && [ -n "$S" ] || die "uso: htaccess-maint.sh on|off|status HTACCESS STATEDIR [PAGE IP...]"
[ -f "$F" ] || die "file non trovato: $F"
mkdir -p "$S"
nocr() { tr -d '\r' < "$1"; }

case "$cmd" in
status)
  b=$(nocr "$F" | grep -cF -- '>>> php-upgrade' || true)
  if [ "$b" = 0 ]; then echo "STATO=off"; else echo "STATO=on"; nocr "$F" | sed -n "/^.*>>> php-upgrade/,/<<< php-upgrade/p" | grep REMOTE_ADDR || true; fi
  ;;

on)
  PAGE=${4:?pagina}; shift 4; [ $# -ge 1 ] || die "serve almeno un IP"
  [[ "$PAGE" =~ ^[A-Za-z0-9._-]+\.html$ ]] || die "nome pagina non valido: $PAGE"
  ips=(); for ip in "$@"; do
    [[ "$ip" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ || "$ip" =~ ^[0-9a-fA-F:]+$ ]] || die "IP non valido: $ip"
    [[ " ${ips[*]-} " == *" $ip "* ]] || ips+=("$ip")
  done
  esc=(); for ip in "${ips[@]}"; do esc+=("$(printf '%s' "$ip" | sed 's/[.]/\\./g')"); done
  alt=$(IFS='|'; echo "${esc[*]}")
  pesc=$(printf '%s' "$PAGE" | sed 's/[.]/\\./g')

  # già attiva?
  if [ "$(nocr "$F" | grep -cxF -- "$BEGIN" || true)" != 0 ] || [ "$(nocr "$F" | grep -cF -- '>>> php-upgrade' || true)" != 0 ]; then
    [ -f "$S/block" ] || die "il .htaccess ha già un blocco php-upgrade ma manca $S/block: controllalo a mano"
    nocr "$F" | sed -n "/>>> php-upgrade/,/<<< php-upgrade/p" | sed 's/^[[:space:]]*//' > "$S/cur.tmp"
    sed 's/^[[:space:]]*//' "$S/block" | tr -d '\r' > "$S/saved.tmp"
    if cmp -s "$S/cur.tmp" "$S/saved.tmp" && grep -qF -- "!^($alt)\$" "$S/cur.tmp"; then rm -f "$S"/*.tmp; echo "STATO=on (già attiva, nessuna modifica)"; exit 0; fi
    rm -f "$S"/*.tmp; die "c'è già un blocco di manutenzione diverso (altri IP o modificato): spegnilo prima con off"
  fi

  n=$(nocr "$F" | grep -niE '^[[:space:]]*RewriteEngine[[:space:]]+On[[:space:]]*$' | head -1 | cut -d: -f1)
  [ -n "$n" ] || die "nel .htaccess non c'è una riga 'RewriteEngine On': non indovino dove inserire, fallo a mano"
  line=$(sed -n "${n}p" "$F")
  indent=$(printf '%s' "$line" | sed -E 's/^([[:space:]]*).*/\1/')
  eol=$'\n'; [[ "$line" == *$'\r' ]] && eol=$'\r\n'
  {
    printf '%s%s%s' "$indent" "$BEGIN" "$eol"
    printf '%s%s%s' "$indent" "ErrorDocument 503 /$PAGE" "$eol"
    printf '%s%s%s' "$indent" "RewriteCond %{REMOTE_ADDR} !^($alt)\$" "$eol"
    printf '%s%s%s' "$indent" "RewriteCond %{REQUEST_URI} !^/$pesc\$" "$eol"
    printf '%s%s%s' "$indent" 'RewriteCond %{REQUEST_URI} !\.(css|js|png|jpe?g|gif|svg|webp|ico|woff2?)$' "$eol"
    printf '%s%s%s' "$indent" 'RewriteCond %{REQUEST_URI} !^/\.well-known/' "$eol"
    printf '%s%s%s' "$indent" 'RewriteRule ^ - [R=503,L]' "$eol"
    printf '%s%s%s' "$indent" "$END" "$eol"
  } > "$S/block"
  cp -p "$F" "$S/htaccess.before"
  { head -n "$n" "$F"; cat "$S/block"; tail -n +"$((n + 1))" "$F"; } > "$F.php-upgrade.tmp"
  # verifica: togliendo il blocco resta il file di partenza, byte per byte
  k=$(wc -l < "$S/block")
  { head -n "$n" "$F.php-upgrade.tmp"; tail -n +"$((n + k + 1))" "$F.php-upgrade.tmp"; } | cmp -s - "$S/htaccess.before" ||
    { rm -f "$F.php-upgrade.tmp"; die "verifica fallita: il file risultante non è l'originale + il blocco (nessuna modifica fatta)"; }
  cat "$F.php-upgrade.tmp" > "$F"   # riscrive il contenuto mantenendo proprietario e permessi del file
  rm -f "$F.php-upgrade.tmp"
  echo "$n" > "$S/line"
  echo "STATO=on IP=${ips[*]} riga=$((n + 1))"
  ;;

off)
  # i marcatori hanno il rientro di RewriteEngine: si confrontano senza spazi iniziali
  b=$(nocr "$F" | sed 's/^[[:space:]]*//' | grep -cxF -- "$BEGIN" || true); e=$(nocr "$F" | sed 's/^[[:space:]]*//' | grep -cxF -- "$END" || true)
  if [ "$b" = 0 ] && [ "$e" = 0 ]; then echo "STATO=off (nessun blocco, nessuna modifica)"; rm -f "$S/block" "$S/line"; exit 0; fi
  [ "$b" = 1 ] && [ "$e" = 1 ] || die "marcatori del blocco non validi (inizio=$b fine=$e): controlla il .htaccess a mano"
  [ -f "$S/block" ] || die "manca $S/block: non so quali righe ho aggiunto, non tolgo nulla"
  start=$(nocr "$F" | sed 's/^[[:space:]]*//' | grep -nxF -- "$BEGIN" | cut -d: -f1)
  stop=$(nocr "$F" | sed 's/^[[:space:]]*//' | grep -nxF -- "$END" | cut -d: -f1)
  [ "$stop" -gt "$start" ] || die "marcatori in ordine sbagliato"
  sed -n "${start},${stop}p" "$F" | cmp -s - "$S/block" || die "le righe tra i marcatori non sono quelle aggiunte (modificate a mano?): non tolgo nulla"
  { head -n "$((start - 1))" "$F"; tail -n +"$((stop + 1))" "$F"; } > "$F.php-upgrade.tmp"
  # verifica: rimettendo il blocco al suo posto si riottiene il file attuale (è cambiato solo il blocco)
  { head -n "$((start - 1))" "$F.php-upgrade.tmp"; cat "$S/block"; tail -n +"$start" "$F.php-upgrade.tmp"; } | cmp -s - "$F" ||
    { rm -f "$F.php-upgrade.tmp"; die "verifica fallita (nessuna modifica fatta)"; }
  cat "$F.php-upgrade.tmp" > "$F"
  rm -f "$F.php-upgrade.tmp" "$S/block" "$S/line"
  echo "STATO=off righe_tolte=$((stop - start + 1))"
  ;;
*) die "comando sconosciuto: $cmd" ;;
esac
