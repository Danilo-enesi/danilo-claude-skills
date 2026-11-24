#!/usr/bin/env bash
# Shared helpers of the check scripts: project paths and OK/WARN/FAIL output.
# Usage: source "$(dirname "$0")/lib.sh" "$@"   (first argument = project root, optional)

ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
VIEWS="$ROOT/private/front/Main/Views"
ASSETS="$ROOT/assets"
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILS=0
WARNS=0

ok()   { printf 'OK    [%s] %s\n' "$1" "$2"; }
warn() { printf 'WARN  [%s] %s -> rules/%s.md\n' "$1" "$2" "$1"; WARNS=$((WARNS + 1)); }
fail() { printf 'FAIL  [%s] %s -> rules/%s.md\n' "$1" "$2" "$1"; FAILS=$((FAILS + 1)); }

# rel <path>: path relative to the project root, for readable output
rel() { printf '%s' "${1#"$ROOT"/}"; }

# has <file> <fixed string>: the file contains the string
has() { grep -qF -- "$2" "$1"; }

# line_of <file> <fixed string>: first line number with the string (empty if none)
line_of() { grep -nF -- "$2" "$1" | head -1 | cut -d: -f1; }

# need_file <rule> <file>: fail and return 1 when the file is missing
need_file() {
  if [ -f "$2" ]; then return 0; fi
  fail "$1" "manca $(rel "$2")"
  return 1
}

# done_checks <name>: summary line and exit code (1 when any FAIL)
done_checks() {
  printf -- '-- %s: %d fail, %d warn\n' "$1" "$FAILS" "$WARNS"
  [ "$FAILS" -eq 0 ]
}
