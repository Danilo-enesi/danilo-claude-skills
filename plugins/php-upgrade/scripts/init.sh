#!/usr/bin/env bash
# Prepara _migration/ in un progetto nuovo (non sovrascrive nulla di esistente).
#   init.sh            dalla radice del progetto (repo git con il sito come in PROD)
# Dopo: compilare _migration/config.sh, le liste e SPEC.md (skill mig-init), poi committare e creare il tag mig/base.
set -euo pipefail
PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "ERRORE: non è un repo git: prima git init + commit del sito come in PROD" >&2; exit 1; }
M="$ROOT/_migration"; T="$PLUGIN_DIR/templates"
mkdir -p "$M/files" "$M/out"
put() { [ -e "$M/$2" ] && echo "   esiste già: _migration/$2" || { cp -r "$T/$1" "$M/$2"; echo "   creato:     _migration/$2"; }; }
put config.sh config.sh
put GUIA.md GUIA.md
put SPEC.md SPEC.md
put patches.php patches.php
put checks.php checks.php
put files/php8_polyfill.inc files/php8_polyfill.inc
for f in urls.txt urls-pdf.txt urls-admin.txt urls-compare.txt lint-ignore.txt argcount-ignore.txt const-ignore.txt; do
  [ -e "$M/$f" ] || { echo "# vedi $T/lists.txt" > "$M/$f"; echo "   creato:     _migration/$f"; }
done
[ -e "$M/libs.lock" ] || printf '%s\n' '# nome versione url sha256(- = da approvare) cartella-nello-zip destinazione da-tenere(csv|glob|-) da-escludere(csv|-)' > "$M/libs.lock"
grep -qx '_migration/out/' "$ROOT/.gitignore" 2>/dev/null || echo "   aggiungi '_migration/out/' a .gitignore"
git -C "$ROOT" rev-parse -q --verify mig/base > /dev/null && echo "   tag mig/base già presente" ||
  echo "   dopo il commit del sito come in PROD: git tag mig/base"
echo "== Ora: compila config.sh e le liste (skill mig-init), poi 'bash $PLUGIN_DIR/scripts/env.sh'"
