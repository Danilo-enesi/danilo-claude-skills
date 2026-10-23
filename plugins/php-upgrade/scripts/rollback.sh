#!/usr/bin/env bash
# Riporta i file del sito (SITE_PATHS) a un commit/tag; default: ultimo commit = annulla il passo in corso.
#   rollback.sh [REF] [--dry-run]      es. rollback.sh mig/base   (= tutto come in produzione)
# Tocca solo i file tracciati e i nuovi file non ignorati; KEEP_UNTRACKED (config generata dal sito) resta.
source "$(dirname "$0")/lib.sh"

REF=HEAD; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    -*) die "argomento sconosciuto: $1" ;;
    *) REF=$1 ;;
  esac; shift
done
banner LOCAL
git -C "$ROOT" rev-parse --verify -q "$REF^{commit}" > /dev/null || die "ref inesistente: $REF"
KEEP=(); for k in "${KEEP_UNTRACKED[@]}"; do KEEP+=(-e "$k"); done

info "file che cambierebbero tornando a $REF:"
git -C "$ROOT" diff --stat "$REF" -- "${SITE_PATHS[@]}" | tail -n 20
git -C "$ROOT" clean -nd "${KEEP[@]}" -- "${SITE_PATHS[@]}"
[ $DRY = 1 ] && { echo "(dry-run) nessuna modifica"; exit 0; }

# L'harness (_migration, .claude, CLAUDE.md) resta com'è: si ripristinano solo i file del sito.
# File nuovi già nell'indice (update-lib.sh fa git add): checkout e clean non li toccano → prima fuori dall'indice
git -C "$ROOT" diff --cached --name-only --diff-filter=A "$REF" -- "${SITE_PATHS[@]}" \
  | git -C "$ROOT" rm -q --cached --pathspec-from-file=- 2>/dev/null || true
git -C "$ROOT" checkout "$REF" -- "${SITE_PATHS[@]}"
git -C "$ROOT" clean -fdq "${KEEP[@]}" -- "${SITE_PATHS[@]}"
git -C "$ROOT" diff --quiet "$REF" -- "${SITE_PATHS[@]}" || die "il ripristino non è completo"
info "OK: file del sito uguali a $REF (ricorda di committare lo stato se REF non è HEAD)"
