#!/usr/bin/env bash
# partials/base/head.blade.php: meta, cookie banner, blocked Google Fonts, versioned local assets, debug/production split.
# Usage: check-head.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
F="$VIEWS/partials/base/head.blade.php"
need_file head "$F" || { done_checks check-head; exit $?; }

meta=$(line_of "$F" "Meta::render()")
banner=$(line_of "$F" "Dom::renderCookieBanner()")
first_asset=$(grep -nE '<(link|script)[ >]' "$F" | head -1 | cut -d: -f1)

if [ -n "$meta" ]; then ok head "Meta::render()"; else fail head "manca {!! Meta::render() !!}"; fi
if [ -n "$banner" ]; then ok cookie-consent "Dom::renderCookieBanner()"; else warn cookie-consent "manca {!! Dom::renderCookieBanner() !!} (obbligatorio se il sito gestisce i cookie)"; fi
if [ -n "$meta" ] && [ -n "$banner" ] && [ "$meta" -gt "$banner" ]; then fail head "Meta::render() va prima del cookie banner"; fi
if [ -n "$banner" ] && [ -n "$first_asset" ] && [ "$banner" -gt "$first_asset" ]; then
  fail cookie-consent "il cookie banner va prima di ogni <link>/<script>"
fi

# Google Fonts only through Meta::googleFonts() (blocked until consent)
if grep -E '<link[^>]+href="https://fonts\.googleapis\.com/css' "$F" >/dev/null; then
  fail cookie-consent "Google Fonts con <link href> diretto: usa Meta::googleFonts(...)"
fi

# Local assets always through Version::get()
while IFS= read -r line; do
  fail assets-versioning "asset locale senza Version::get(): $(echo "$line" | sed 's/^ *//')"
done < <(grep -E "(href|src)=\"(/assets/|\{\{ *asset\()" "$F" | grep -v 'Version::get')

# Debug/production split of our styles
if has "$F" "@if(config('app.debug'))" && has "$F" "/assets/main/css/base.min.css"; then
  ok assets-versioning "split debug/produzione dei CSS"
else
  fail assets-versioning "manca lo split @if(config('app.debug')) main.css/responsive.css vs base.min.css"
fi
for css in /assets/main/css/main.css /assets/main/css/responsive.css; do
  has "$F" "$css" || fail assets-versioning "manca $css nel ramo debug"
done

# Google tag: blocked loader, statistics category
if has "$F" "googletagmanager.com"; then
  if has "$F" 'data-epp-src="https://www.googletagmanager.com' && has "$F" 'data-epp-category="10002"'; then
    ok cookie-consent "gtag bloccato (10002)"
  else
    fail cookie-consent "gtag non bloccato: data-epp-onconsent + data-epp-category=\"10002\" + data-epp-src"
  fi
fi

done_checks check-head
