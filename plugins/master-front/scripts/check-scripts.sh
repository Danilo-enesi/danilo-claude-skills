#!/usr/bin/env bash
# partials/base/scripts.blade.php: window.front first, libraries before our scripts, debug/production split, Beers callbacks.
# Usage: check-scripts.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
F="$VIEWS/partials/base/scripts.blade.php"
need_file scripts "$F" || { done_checks check-scripts; exit $?; }

front=$(line_of "$F" "window.front = {")
first_src=$(grep -nE '<script[^>]+src=' "$F" | head -1 | cut -d: -f1)

if [ -n "$front" ]; then ok scripts "window.front"; else fail scripts "manca la config window.front = { ... }"; fi
if [ -n "$front" ] && [ -n "$first_src" ] && [ "$front" -gt "$first_src" ]; then
  fail scripts "window.front deve essere il primo script, prima di ogni <script src>"
fi
for key in "route:" "base_url:" "lang:" "translations_front_"; do
  has "$F" "$key" || fail scripts "window.front incompleto: manca $key"
done

# Local scripts through Version::get()
while IFS= read -r line; do
  fail assets-versioning "script locale senza Version::get(): $(echo "$line" | sed 's/^ *//')"
done < <(grep -E "src=\"(/assets/|\{\{ *asset\()" "$F" | grep -v 'Version::get')

# Debug/production split
if has "$F" "@if(config('app.debug'))" && has "$F" "/assets/main/js/base.min.js" && has "$F" "/assets/main/js/main.js"; then
  ok assets-versioning "split debug/produzione dei JS"
else
  fail assets-versioning "manca lo split @if(config('app.debug')) main.js vs base.min.js"
fi

# Libraries (CDN or lib/) before the theme block
theme=$(line_of "$F" "@if(config('app.debug'))")
if [ -n "$theme" ]; then
  while IFS=: read -r n _; do
    [ "$n" -gt "$theme" ] && fail scripts "libreria caricata dopo i nostri script (riga $n): le librerie vanno prima"
  done < <(grep -nE '<script[^>]+src=' "$F" | grep -vE '/assets/(main/js|common/beers)/')
fi

# Beers first in the debug branch: our scripts use it
beers=$(line_of "$F" "/assets/common/beers/beers.js"); main=$(line_of "$F" "/assets/main/js/main.js")
if [ -z "$beers" ]; then fail scripts "manca beers.js nel ramo debug"
elif [ -n "$main" ] && [ "$beers" -gt "$main" ]; then fail scripts "beers.js va caricato prima di main.js"
else ok scripts "beers.js prima dei nostri script"; fi

# Beers callbacks from the session
if has "$F" "session()->has('callbacks')" && has "$F" "Beers.callbacks.fireList"; then
  ok scripts "callbacks di Beers"
else
  fail scripts "manca il blocco @if(session()->has('callbacks')) ... Beers.callbacks.fireList"
fi

# Only scripts here: no markup (e.g. the back-to-top button belongs to the layout/partials)
if grep -qiE '<(button|a|div|img|span)[ >]' "$F"; then
  fail scripts "markup dentro scripts.blade.php (es. bottone torna-su): va in un partial"
fi

done_checks check-scripts
