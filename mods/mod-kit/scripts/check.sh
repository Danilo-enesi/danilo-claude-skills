#!/usr/bin/env bash
# Valida e testa un mod: check.sh <cartella-mod>. Esce != 0 al primo errore.
set -euo pipefail
dir="${1:?uso: check.sh <cartella-mod>}"
out=$(claude plugin validate "$dir" 2>&1) || { echo "$out"; exit 1; }
# the plugin-directory block (README/LICENSE/icon) only matters for publishing: skip it
echo "$out" | grep -E '^\s*❯ .*(hooks:|gating|refus)|✔|✘' | grep -v 'plugin directory' || true
claude plugin test "$dir" 2>&1 | tail -4
