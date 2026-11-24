#!/usr/bin/env bash
# Runs every front check. Exit 1 when any of them fails.
# Usage: check-all.sh [project-root]
DIR="$(dirname "$0")"
status=0
for check in views layout head scripts assets; do
  echo "== check-$check"
  bash "$DIR/check-$check.sh" "$@" || status=1
done
[ "$status" -eq 0 ] && echo "== TUTTO OK" || echo "== CI SONO FAIL: leggi la regola indicata a destra di ogni riga"
exit "$status"
