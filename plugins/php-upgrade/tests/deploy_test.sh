#!/usr/bin/env bash
# Test di remote/deploy.sh su un "server" finto in una cartella locale.
set -uo pipefail
D="$(cd "$(dirname "$0")/.." && pwd)/remote/deploy.sh"
T=$(mktemp -d); fail=0
ok() { echo "ok   $*"; }; ko() { echo "FAIL $*"; fail=1; }
sha() { sha256sum "$1" | cut -d' ' -f1; }
snapshot() { (cd "$1" && find . -type f | sort | xargs sha256sum); }

# PROD come mig/base
R="$T/site"; mkdir -p "$R/lib/old" "$R/app"
echo idx > "$R/index.php"; echo "a v1" > "$R/app/a.php"; echo "da togliere" > "$R/app/d.php"
echo "lib v1" > "$R/lib/old/x.php"; echo "font generato in PROD" > "$R/lib/old/f.php"; echo "intatto" > "$R/app/keep.php"
snapshot "$R" > "$T/before.txt"
# pacchetto: a modificato, b nuovo, d cancellato, lib sostituita intera
P="$T/pack"; mkdir -p "$P/app" "$P/lib/old"
echo "a v2" > "$P/app/a.php"; echo "b nuovo" > "$P/app/b.php"; echo "lib v2" > "$P/lib/old/y.php"
tar -czf "$T/deploy.tar.gz" -C "$P" .
{
  echo "BASE M $(sha "$R/app/a.php") app/a.php"
  echo "BASE D $(sha "$R/app/d.php") app/d.php"
  echo "BASE M $(sha "$R/lib/old/x.php") lib/old/x.php"
  echo "ADD app/b.php"; echo "ADD lib/old/y.php"; echo "LIBDIR lib/old"
  (cd "$P" && find . -type f | sed 's#^\./##' | while read -r f; do echo "PKG $(sha "$f") $f"; done)
} > "$T/manifest.txt"

bash "$D" check "$R" "$T/manifest.txt" > "$T/out" 2>&1 && ok "check: PROD = base" || ko "check: $(cat "$T/out")"
bash "$D" apply "$R" "$T/manifest.txt" "$T/deploy.tar.gz" "$T/job1" > "$T/out" 2>&1 && ok "apply" || ko "apply: $(cat "$T/out")"
[ "$(cat "$R/app/a.php")" = "a v2" ] && [ -f "$R/app/b.php" ] && [ ! -e "$R/app/d.php" ] && [ ! -e "$R/lib/old/x.php" ] && [ -f "$R/lib/old/y.php" ] && [ "$(cat "$R/app/keep.php")" = intatto ] \
  && ok "file applicati, libreria sostituita intera, resto intatto" || ko "stato dopo apply"
bash "$D" apply "$R" "$T/manifest.txt" "$T/deploy.tar.gz" "$T/job1" > "$T/out" 2>&1 && ko "riapplica lo stesso job" || ok "stesso job non riapplicabile"
bash "$D" rollback "$R" "$T/job1" > "$T/out" 2>&1 && ok "rollback" || ko "rollback: $(cat "$T/out")"
snapshot "$R" | diff -q - "$T/before.txt" > /dev/null && ok "dopo rollback PROD identico a prima (anche il font generato in PROD)" || ko "rollback non identico: $(snapshot "$R" | diff - "$T/before.txt")"

# errore a metà (pacchetto che non corrisponde al manifest): ripristino automatico
sed -i 's/^PKG [0-9a-f]* app\/a.php$/PKG 0000000000000000000000000000000000000000000000000000000000000000 app\/a.php/' "$T/manifest.txt"
bash "$D" apply "$R" "$T/manifest.txt" "$T/deploy.tar.gz" "$T/job2" > "$T/out" 2>&1 && ko "apply con SHA sbagliato accettato" || {
  grep -q "ripristino fatto" "$T/out" && snapshot "$R" | diff -q - "$T/before.txt" > /dev/null && ok "SHA sbagliato: ripristino automatico, PROD identico a prima" || ko "ripristino automatico: $(cat "$T/out")"; }

# PROD cambiato dopo mig/base: si ferma prima di toccare
echo "modificato in PROD" > "$R/app/a.php"; snapshot "$R" > "$T/changed.txt"
bash "$D" apply "$R" "$T/manifest.txt" "$T/deploy.tar.gz" "$T/job3" > "$T/out" 2>&1 && ko "PROD cambiato accettato" || {
  grep -q "cambiato in PROD" "$T/out" && snapshot "$R" | diff -q - "$T/changed.txt" > /dev/null && ok "PROD cambiato: si ferma senza toccare" || ko "PROD cambiato: $(cat "$T/out")"; }

# manifest con percorso pericoloso
printf 'PKG abc ../../etc/passwd\n' > "$T/evil.txt"
bash "$D" check "$R" "$T/evil.txt" > "$T/out" 2>&1 && ko "percorso ../ accettato" || ok "percorsi con ../ rifiutati"
bash "$D" check "$T" "$T/manifest.txt" > "$T/out" 2>&1 && ko "radice senza index.php accettata" || ok "radice del sito validata"

rm -rf "$T"
[ $fail = 0 ] && echo "== deploy: tutto ok" || { echo "== deploy: errori"; exit 1; }
