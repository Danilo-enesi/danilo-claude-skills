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
rm -rf "$T"

[ $fail = 0 ] && echo "== tutto ok" || { echo "== ci sono errori"; exit 1; }
