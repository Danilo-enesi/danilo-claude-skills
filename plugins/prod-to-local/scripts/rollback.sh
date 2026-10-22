#!/usr/bin/env bash
# Undoes everything a job created, newest first (remote temp files, downloads, project folder).
# --forget: the job succeeded; drop the ledger and the folder markers, undo nothing.
# Usage: rollback.sh --job J [--forget]
source "$(dirname "$0")/lib.sh"

forget=no
while [ $# -gt 0 ]; do
  case "$1" in
    --job) job=$2; shift 2 ;; --forget) forget=yes; shift ;;
    *) die "unknown option $1" ;;
  esac
done
check_name job "${job:?--job}"
LEDGER="$STATE_DIR/jobs/$job.ledger"
[ -f "$LEDGER" ] || { echo "nothing to do: no ledger for job '$job'"; exit 0; }

if [ "$forget" = yes ]; then
  grep -q '^remote-file' "$LEDGER" && die "ledger still lists server files: run without --forget first"
  while IFS=$'\t' read -r kind path; do
    [ "$kind" = local-dir ] && rm -f "$path/.prod-to-local.job"
  done < "$LEDGER"
  rm -f "$LEDGER"; echo "job '$job' committed: ledger removed"; exit 0
fi

failed=0
while IFS=$'\t' read -r kind a b c d e; do
  case "$kind" in
    remote-file)
      ssh_target "$a" "$b" "$c" "$d"
      if remote cleanup.sh "$e"; then ledger_del "$kind" "$a" "$b" "$c" "$d" "$e"; else failed=1; echo "!! could not delete \$HOME/$e on $b: delete it by hand" >&2; fi ;;
    local-file)
      rm -f -- "$a" && ledger_del "$kind" "$a" && echo "removed $a" ;;
    local-dir)
      if [ ! -e "$a" ]; then ledger_del "$kind" "$a"
      elif [ "$(cat "$a/.prod-to-local.job" 2>/dev/null)" = "$job" ]; then rm -rf -- "$a" && ledger_del "$kind" "$a" && echo "removed $a"
      else failed=1; echo "!! $a has no marker for job '$job': NOT deleted" >&2; fi ;;
    "") ;;
    *) failed=1; echo "!! unknown ledger entry: $kind" >&2 ;;
  esac
done < <(tac "$LEDGER")

[ "$failed" -eq 0 ] || die "rollback incomplete, ledger kept: $LEDGER"
rm -f "$LEDGER"; echo "job '$job' rolled back"
