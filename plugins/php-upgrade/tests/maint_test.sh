#!/usr/bin/env bash
# Test di remote/htaccess-maint.sh: aggiunge/toglie solo il suo blocco, byte per byte.
set -uo pipefail
H="$(cd "$(dirname "$0")/.." && pwd)/remote/htaccess-maint.sh"
T=$(mktemp -d); fail=0
ok() { echo "ok   $*"; }; ko() { echo "FAIL $*"; fail=1; }
run() { bash "$H" "$@" > "$T/out" 2>&1; }

for eol in lf crlf; do
  F="$T/$eol.htaccess"; S="$T/state-$eol"
  printf '# testa\nOptions -Indexes\n<IfModule mod_rewrite.c>\n    RewriteEngine On\n\n    RewriteCond %%{HTTPS} off\n    RewriteRule ^(.*)$ https://%%{HTTP_HOST}/$1 [L,R=301]\n</IfModule>\n' > "$F"
  [ $eol = crlf ] && sed -i 's/$/\r/' "$F"
  cp "$F" "$T/orig"
  run on "$F" "$S" manutenzione.html 79.58.24.43 2001:db8::1 && ok "$eol on" || ko "$eol on: $(cat "$T/out")"
  n=$(grep -n 'RewriteEngine' "$F" | cut -d: -f1)
  sed -n "$((n + 1))p" "$F" | grep -q '^    # >>> php-upgrade' && ok "$eol blocco subito dopo RewriteEngine, stesso rientro" || ko "$eol posizione"
  grep -qF 'RewriteCond %{REMOTE_ADDR} !^(79\.58\.24\.43|2001:db8::1)$' "$F" && ok "$eol IP" || ko "$eol IP: $(grep REMOTE_ADDR "$F")"
  [ $eol = crlf ] && { [ "$(grep -c $'\r$' "$F")" = "$(wc -l < "$F")" ] && ok "crlf mantenuto" || ko "crlf misto"; }
  [ "$(( $(wc -l < "$F") - $(wc -l < "$T/orig") ))" = 8 ] && ok "$eol solo 8 righe aggiunte" || ko "$eol righe aggiunte"
  run on "$F" "$S" manutenzione.html 79.58.24.43 2001:db8::1 && grep -q 'già attiva' "$T/out" && ok "$eol on idempotente" || ko "$eol idempotenza: $(cat "$T/out")"
  cp "$F" "$T/on"
  run on "$F" "$S" manutenzione.html 1.2.3.4 && ko "$eol on con altro IP accettato" || { cmp -s "$F" "$T/on" && ok "$eol altro IP rifiutato, file intatto" || ko "$eol file cambiato"; }
  run status "$F" "$S" && grep -q 'STATO=on' "$T/out" && ok "$eol status on" || ko "$eol status"
  run off "$F" "$S" && cmp -s "$F" "$T/orig" && ok "$eol off = file originale byte per byte" || ko "$eol off: $(cat "$T/out")"
  run off "$F" "$S" && grep -q 'nessun blocco' "$T/out" && cmp -s "$F" "$T/orig" && ok "$eol off idempotente" || ko "$eol off 2"
done

# blocco modificato a mano: off rifiuta e non tocca nulla
F="$T/mod.htaccess"; S="$T/state-mod"
printf 'RewriteEngine On\nRewriteRule ^x$ /y [L]\n' > "$F"
run on "$F" "$S" manutenzione.html 10.0.0.1
sed -i 's/R=503,L/R=503,L,NC/' "$F"; cp "$F" "$T/edited"
run off "$F" "$S" && ko "off con blocco modificato accettato" || { cmp -s "$F" "$T/edited" && ok "blocco modificato: off rifiuta, file intatto" || ko "file toccato"; }
# altre righe aggiunte da qualcuno fuori dal blocco: off toglie solo il blocco
F="$T/other.htaccess"; S="$T/state-other"
printf 'RewriteEngine On\nRewriteRule ^a$ /b [L]\n' > "$F"
run on "$F" "$S" manutenzione.html 10.0.0.1
echo 'Header set X-Prova 1' >> "$F"
run off "$F" "$S" && [ "$(cat "$F")" = "$(printf 'RewriteEngine On\nRewriteRule ^a$ /b [L]\nHeader set X-Prova 1')" ] && ok "righe altrui conservate" || ko "righe altrui: $(cat "$F")"
# senza RewriteEngine: non indovina
printf 'Options -Indexes\n' > "$T/none.htaccess"; cp "$T/none.htaccess" "$T/none.orig"
run on "$T/none.htaccess" "$T/state-none" manutenzione.html 10.0.0.1 && ko "senza RewriteEngine accettato" || { cmp -s "$T/none.htaccess" "$T/none.orig" && ok "senza RewriteEngine: rifiuta" || ko "file toccato"; }
# input non validi
printf 'RewriteEngine On\n' > "$T/v.htaccess"
run on "$T/v.htaccess" "$T/sv" '../x.html' 10.0.0.1 && ko "pagina con ../ accettata" || ok "nome pagina validato"
run on "$T/v.htaccess" "$T/sv" manutenzione.html '1.2.3.4$ [L]' && ko "IP non valido accettato" || ok "IP validato"

rm -rf "$T"
[ $fail = 0 ] && echo "== htaccess-maint: tutto ok" || { echo "== htaccess-maint: errori"; exit 1; }
