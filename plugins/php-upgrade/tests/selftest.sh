#!/usr/bin/env bash
# Autotest del plugin: sintassi degli script, guardia, scanner A1/A2 su un progetto finto.
set -euo pipefail
P="$(cd "$(dirname "$0")/.." && pwd)"
PHP=${PHP:-$(ls -d /c/dunebox/system/apps/php/php-8.*-x64 2>/dev/null | sort -V | tail -1)/php.exe}
fail=0
ok()  { echo "ok   $*"; }
ko()  { echo "FAIL $*"; fail=1; }

for f in "$P"/scripts/*.sh; do bash -n "$f" && ok "bash -n $(basename "$f")" || ko "bash -n $(basename "$f")"; done
for f in "$P"/scripts/*.php "$P"/lib/*.php "$P"/templates/*.php; do "$PHP" -l "$f" > /dev/null && ok "php -l $(basename "$f")" || ko "php -l $(basename "$f")"; done
python -I "$P/tests/guard_test.py" && ok "guardia" || ko "guardia"
bash "$P/tests/maint_test.sh" > /dev/null && ok "manutenzione (.htaccess)" || { bash "$P/tests/maint_test.sh" | grep FAIL; ko "manutenzione"; }
bash "$P/tests/deploy_test.sh" > /dev/null && ok "deploy remoto (istantanea, rollback)" || { bash "$P/tests/deploy_test.sh" | grep FAIL; ko "deploy"; }
for f in "$P"/remote/*.sh; do bash -n "$f" && ok "bash -n remote/$(basename "$f")" || ko "bash -n remote/$(basename "$f")"; done

# A1/A2 su un progetto finto: devono trovare i casi veri e ignorare definizioni, nativi e protetti da defined()
T=$(mktemp -d); mkdir -p "$T/admin/lang" "$T/lib" "$T/front/app/settings/lang/w1"
printf "<?php\ndefine('ONLY_ITA', 'x');\ndefine('BOTH', 'x');\n" > "$T/front/app/settings/lang/w1/language_ita.inc"
printf "<?php\ndefine('BOTH', 'y');\n" > "$T/front/app/settings/lang/w1/language_eng.inc"
printf "<?php\necho BOTH, ONLY_ITA, NOWHERE;\n" > "$T/front/f.php"
cat > "$T/a.php" <<'EOF'
<?php
define('OK_CONST', 1);
function f($a, $b = null) {}
class C { function m($x) {} }
f();                         // A1: 0 argomenti, richiesti 1
f(1);
(new C)->m(1);
echo OK_CONST, PDF_UNIT, E_ALL, MISSING_CONST;   // A2: solo MISSING_CONST (PDF_UNIT definita in lib/)
echo defined('GUARDED') ? GUARDED : '';
EOF
printf "<?php\necho FROM_LANG;\n" > "$T/admin/x.php"   # traduzione dell'admin: basta una lingua
echo "<?php define('PDF_UNIT', 'mm');" > "$T/lib/tcpdf.php"
echo '[{"codice":"FROM_LANG","valore":"x"}]' > "$T/admin/lang/language_ita_php.inc"
a1=$(MIG_ROOT="$T" MIG_SKIP_PREFIXES="lib/" "$PHP" -d short_open_tag=1 "$P/scripts/scan-argcount.php" || true)
a2=$(MIG_ROOT="$T" MIG_SKIP_PREFIXES="lib/" "$PHP" -d short_open_tag=1 "$P/scripts/scan-undefconst.php" || true)
[ "$(echo "$a1" | grep -c .)" = 1 ] && echo "$a1" | grep -q 'a.php:5 f() passati=0' && ok "A1" || ko "A1: $a1"
[ "$(echo "$a2" | grep -c .)" = 3 ] && echo "$a2" | grep -q 'a.php:8 MISSING_CONST — senza definizione' \
  && echo "$a2" | grep -q 'f.php:2 ONLY_ITA — traduzione mancante in: eng (front)' && echo "$a2" | grep -q 'f.php:2 NOWHERE — senza' \
  && ok "A2" || ko "A2: $a2"
a3=$(MIG_ROOT="$T" "$PHP" "$P/scripts/scan-langs.php" || true)
[ "$(echo "$a3" | grep -c .)" = 1 ] && echo "$a3" | grep -q 'w1 eng ONLY_ITA' && ok "A3" || ko "A3: $a3"
MIG_ROOT="$T" "$PHP" "$P/scripts/scan-langs.php" --sql | grep -q "SELECT 'w1' s, 'ONLY_ITA' c, 'eng' l, 'x' v" && ok "A3 --sql" || ko "A3 --sql"
cat > "$T/route.json" <<'EOF'
{"default": {"callable": "X"}, "notFound": "X::nf", "map": {
  "home": {"pattern": {"it": "/it/", "en": "/en/"}},
  "news": {"pattern": {"it": "/it/news(/:slug)", "en": "/en/news(/:slug)"}},
  "pdf":  {"pattern": {"it": "/it/p/:slug.pdf", "en": "/en/p/:slug.pdf"}},
  "solo": {"pattern": {"it": "/it/solo/"}}}}
EOF
urls=$("$PHP" "$P/scripts/urls-from-routes.php" "$T/route.json" 2>"$T/err.txt" | paste -sd' ')
[ "$urls" = "/it/ /en/ /it/news /en/news /it/solo/" ] && grep -q "senza lingua en" "$T/err.txt" && grep -q "parametri obbligatori" "$T/err.txt" \
  && ok "urls-from-routes" || ko "urls-from-routes: $urls / $(cat "$T/err.txt")"
rm -rf "$T"

[ $fail = 0 ] && echo "== tutto ok" || { echo "== ci sono errori"; exit 1; }
