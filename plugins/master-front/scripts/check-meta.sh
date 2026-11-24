#!/usr/bin/env bash
# Every front controller method that returns a view sets title, description and canonical (canonical not needed with noindex).
# Usage: check-meta.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
C="$ROOT/private/front/Main/Controllers"
if [ ! -d "$C" ]; then
  warn meta "manca $(rel "$C"): nessun controller da controllare"
  done_checks check-meta; exit $?
fi

while IFS= read -r file; do
  # One line per method that returns a view: "<line> <name> <has title> <has description> <has canonical> <noindex>"
  while read -r line name t d c n; do
    missing=()
    [ "$t" = 1 ] || missing+=(title)
    [ "$d" = 1 ] || missing+=(description)
    [ "$c" = 1 ] || [ "$n" = 1 ] || missing+=(canonical)
    if [ ${#missing[@]} -eq 0 ]; then
      ok meta "$(rel "$file"):$line $name()"
    else
      fail meta "$(rel "$file"):$line $name(): manca Meta::set per ${missing[*]}"
    fi
  done < <(awk '
    function flush() {
      if (name != "" && view) print start, name, t, d, c, n
      name = ""; view = t = d = c = n = 0
    }
    /function[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]*\(/ {
      flush()
      match($0, /function[ \t]+[A-Za-z_][A-Za-z0-9_]*/)
      name = substr($0, RSTART, RLENGTH); sub(/function[ \t]+/, "", name); start = NR
    }
    /return[ \t]+view\(/                  { view = 1 }
    /Meta::set\([ \t]*["\x27]title["\x27]/       { t = 1 }
    /Meta::set\([ \t]*["\x27]description["\x27]/ { d = 1 }
    /Meta::set\([ \t]*["\x27]canonical["\x27]/   { c = 1 }
    /Meta::set\([ \t]*["\x27]robots["\x27].*noindex/ { n = 1 }
    END { flush() }
  ' "$file")
done < <(find "$C" -name '*.php')

# Core bug (several laravel-master-core versions): canonical printed as <meta name="canonical">. Fixed when the core
# or the local Meta (private/master/Foundation/Meta.php, the class the core binds as 'Meta') renders it as <link>.
CORE="$ROOT/private/vendor/enesisrl/laravel-master-core/src/Foundation/Meta.php"
LOCAL="$ROOT/private/master/Foundation/Meta.php"
# <link rel="canonical" ...> written out, or built from the name: '<link rel="' . e($name) (any spacing, Pint
# removes it), "<link rel=\"{$name}\"" or sprintf('<link rel="%s"', ...)
LINKED_RE='<link rel=\\?"(canonical|'"'"'[[:space:]]*\.[[:space:]]*(e|htmlspecialchars|\$)|\{?\$name|%s)'
linked() { [ -f "$1" ] && grep -q 'canonical' "$1" && grep -qE "$LINKED_RE" "$1"; }
if [ ! -f "$CORE" ]; then
  warn meta "manca $(rel "$CORE") (composer install?): impossibile controllare il bug del canonical"
elif linked "$CORE"; then
  ok meta "il core stampa il canonical come <link>"
elif linked "$LOCAL"; then
  ok meta "bug del canonical corretto in $(rel "$LOCAL")"
else
  fail meta "il core stampa il canonical come <meta>: correggilo in $(rel "$LOCAL") (render_property)"
fi

done_checks check-meta
