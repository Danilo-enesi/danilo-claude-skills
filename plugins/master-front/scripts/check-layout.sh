#!/usr/bin/env bash
# layouts/main.blade.php: html lang, body classes, head/scripts includes with their stacks, main content.
# Usage: check-layout.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
F="$VIEWS/layouts/main.blade.php"
need_file layout-main "$F" || { done_checks check-layout; exit $?; }

check() { # check <fixed string> <message>
  if has "$F" "$1"; then ok layout-main "$2"; else fail layout-main "manca $2: $1"; fi
}

# html lang: the base form, or lang/dir from the view composer of rules/lang-rtl.md (sites with RTL/CJK languages)
if has "$F" "<html lang=\"{{ \$htmlLang }}\" dir=\"{{ \$htmlDir }}\">"; then
  ok layout-main "lang e dir dell'html (composer)"
else
  check "<html lang=\"{{ Websites::currentLanguage('iso_code2') }}\">" "lang dell'html"
fi
check "lang-{{ Websites::currentLanguage('iso_code2') }}" "classe body lang-"
check "route-{{ Front::currentRouteName() }}" "classe body route-"
check "@include('partials.base.head')" "include di head"
check "@stack('styles')" "stack styles"
check "@include('partials.base.scripts')" "include di scripts"
check "@stack('scripts')" "stack scripts"
check '<main class="main"' "contenitore main"
check 'id="main"' "id=\"main\" sul <main> (destinazione dello skip link)"
check 'href="#main"' "skip link verso #main"
check "@yield('content')" "yield content"

# Order: include first, then its stack (pages can override/extend what the base loads)
order() { # order <first> <second> <message>
  local a b; a=$(line_of "$F" "$1"); b=$(line_of "$F" "$2")
  if [ -n "$a" ] && [ -n "$b" ] && [ "$a" -gt "$b" ]; then fail layout-main "$3"; fi
}
order "@include('partials.base.head')" "@stack('styles')" "@stack('styles') deve stare DOPO l'include di head"
order "@include('partials.base.scripts')" "@stack('scripts')" "@stack('scripts') deve stare DOPO l'include di scripts"
order "@stack('styles')" "</head>" "@stack('styles') deve stare dentro <head>"
order "@stack('scripts')" "</body>" "@stack('scripts') deve stare prima di </body>"

# Hooks are stacks, never yields (a @section accepts a single contributor)
if grep -qE "@yield\(['\"](head|styles|scripts)['\"]" "$F"; then
  fail layout-main "usa @stack, non @yield, per styles/scripts"
fi

done_checks check-layout
