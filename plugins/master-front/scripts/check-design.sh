#!/usr/bin/env bash
# DESIGN.md in the project root is mandatory; the project's CLAUDE.md should point the front work to it.
# Usage: check-design.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"

if [ -f "$ROOT/DESIGN.md" ]; then
  ok design-md "DESIGN.md"
  head -1 "$ROOT/DESIGN.md" | grep -q '^---' || warn design-md "DESIGN.md senza front matter YAML (--- all'inizio): i token vanno lì"
else
  fail design-md "manca DESIGN.md nella root: lo crea /master-front:scaffold"
fi

if [ -f "$ROOT/CLAUDE.md" ]; then
  if grep -qF 'DESIGN.md' "$ROOT/CLAUDE.md"; then ok design-md "CLAUDE.md rimanda a DESIGN.md"
  else warn design-md "CLAUDE.md non cita DESIGN.md: aggiungi la sezione «Front: design system» (la scrive lo scaffold)"; fi
fi

done_checks check-design
