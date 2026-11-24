#!/usr/bin/env bash
# Quick read-only checklist of what the site must have (sitemap, structured data, llms.txt, robots.txt, SEO, Core Web Vitals).
# Only reports: missing items are WARN, never FAIL, because this plugin does not manage them (see rules/site-checklist.md).
# Usage: check-site.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
R=site-checklist
# Master shared-hosting layout: the project root is the web root; plain Laravel serves public/.
WEB="$ROOT"; [ -f "$ROOT/index.php" ] || { [ -d "$ROOT/public" ] && WEB="$ROOT/public"; }
ROBOTS="$WEB/robots.txt"

# robots.txt
if [ -f "$ROBOTS" ]; then
  ok $R "$(rel "$ROBOTS")"
  grep -qiE '^[[:space:]]*Disallow:[[:space:]]*/[[:space:]]*$' "$ROBOTS" && warn $R "$(rel "$ROBOTS"): 'Disallow: /' blocca tutto (ok solo in staging)"
else
  warn $R "manca $(rel "$ROBOTS")"
fi

# sitemap: generated files, or at least the command that generates them
if [ -d "$WEB/sitemaps" ] || [ -f "$WEB/sitemap.xml" ]; then
  ok $R "sitemap: $( [ -d "$WEB/sitemaps" ] && rel "$WEB/sitemaps/" || rel "$WEB/sitemap.xml")"
elif grep -rqil 'sitemap' "$ROOT/private/app/Console" 2>/dev/null; then
  warn $R "sitemap: c'è il comando ma nessun file generato (sitemaps/ o sitemap.xml)"
else
  warn $R "sitemap: nessuna sitemap né comando che la generi"
fi
[ -f "$ROBOTS" ] && ! grep -qi '^[[:space:]]*Sitemap:' "$ROBOTS" && warn $R "$(rel "$ROBOTS"): manca la riga 'Sitemap: https://...'"

# llms.txt
if [ -f "$WEB/llms.txt" ]; then ok $R "$(rel "$WEB/llms.txt")"; else warn $R "manca $(rel "$WEB/llms.txt")"; fi

# structured data (JSON-LD)
if grep -rqlE 'application/ld\+json|StructuredData|structured_data' "$ROOT/private/front" "$ROOT/private/master/Foundation" 2>/dev/null; then
  ok $R "structured data (JSON-LD) presente nel front"
else
  warn $R "structured data: nessun JSON-LD nel front"
fi

# SEO on-page: summary of check-meta (its own lines stay in check-meta.sh)
meta_fails=$(bash "$(dirname "$0")/check-meta.sh" "$ROOT" | grep -c '^FAIL')
if [ "$meta_fails" -eq 0 ]; then ok $R "SEO on-page: check-meta senza FAIL"; else warn $R "SEO on-page: $meta_fails FAIL in check-meta.sh"; fi

# Core Web Vitals cannot be read from the code
warn $R "Core Web Vitals: da misurare sul sito online (agent-skills:webperf o claude-seo:seo-performance)"

done_checks check-site
