#!/usr/bin/env bash
# Views structure + no inline CSS/JS in the Blade files.
# Usage: check-views.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"

if [ ! -d "$VIEWS" ]; then
  fail views-structure "manca $(rel "$VIEWS")"
  done_checks check-views; exit $?
fi

for dir in layouts partials components pages mail; do
  if [ -d "$VIEWS/$dir" ]; then ok views-structure "Views/$dir"; else fail views-structure "manca Views/$dir/"; fi
done

need_file views-structure "$VIEWS/layouts/main.blade.php" && ok views-structure "layouts/main.blade.php"
need_file views-structure "$VIEWS/partials/base/head.blade.php" && ok views-structure "partials/base/head.blade.php"
need_file views-structure "$VIEWS/partials/base/scripts.blade.php" && ok views-structure "partials/base/scripts.blade.php"

# layouts/ holds only layouts: a file there that gets @include'd is a partial in the wrong folder
if [ -d "$VIEWS/layouts" ]; then
  while IFS= read -r file; do
    name="layouts.$(basename "$file" .blade.php)"
    if grep -rqE "@include(If|When|First)?\(['\"]$name['\"]" "$VIEWS"; then
      fail views-structure "$(rel "$file"): è incluso come partial, in layouts/ vivono solo layout (spostalo in partials/)"
    elif ! grep -rqE "@extends\(['\"]$name['\"]" "$VIEWS"; then
      warn views-structure "$(rel "$file"): nessuna vista fa @extends('$name')"
    fi
  done < <(find "$VIEWS/layouts" -name '*.blade.php')
fi

# Legacy folder: head/scripts/layout under base/ belong to the old structure
if [ -d "$VIEWS/base" ]; then
  fail views-structure "Views/base/ è la struttura vecchia: layout in layouts/, head e scripts in partials/base/"
fi

# No inline CSS/JS. partials/base/ is the only place allowed to hold <script> (window.front, gtag, callbacks);
# mail/ is skipped because email clients only read inline CSS.
while IFS= read -r file; do
  case "$file" in "$VIEWS/partials/base/"* | "$VIEWS/mail/"*) continue ;; esac
  if grep -qiE '<style[ >]' "$file"; then fail no-inline "$(rel "$file"): blocco <style> inline"; fi
  if grep -iE '<script[ >]' "$file" | grep -qviE 'application/ld\+json'; then
    fail no-inline "$(rel "$file"): <script> inline (usa @push('scripts') con un file in assets/main/js/)"
  fi
  if grep -qiE '\son(click|change|submit|load|input|keyup|keydown)=' "$file"; then
    fail no-inline "$(rel "$file"): handler JS inline (on...=)"
  fi
  if grep -qiE '\sstyle="' "$file"; then
    warn no-inline "$(rel "$file"): attributo style=\"\" (ok solo per valori dinamici, es. background-image)"
  fi
done < <(find "$VIEWS" -name '*.blade.php')

# Blade directives over raw PHP (this applies to partials/base/ too)
while IFS= read -r file; do
  grep -qE '<\?php|<\?=' "$file" && fail blade-directives "$(rel "$file"): PHP crudo (<?php): usa le direttive Blade"
  grep -qE '@php\b' "$file" && warn blade-logic "$(rel "$file"): @php: solo per una variabile banale, la logica va nel controller o in un viewController"
  grep -qE '\{!! *json_encode\(' "$file" && fail blade-directives "$(rel "$file"): {!! json_encode() !!}: usa @json() o Js::from()"
done < <(find "$VIEWS" -name '*.blade.php')

# Translations: @lang for element text (not escaped), {{ __() }} inside attributes (escaped)
while IFS= read -r file; do
  grep -qE '="[^"]*@(lang|choice)\(' "$file" \
    && fail translations "$(rel "$file"): @lang dentro un attributo: usa {{ __('...') }} (escapa l'HTML)"
  grep -qE '>[[:space:]]*\{\{ *__\(' "$file" \
    && warn translations "$(rel "$file"): {{ __() }} come testo di un elemento: usa @lang (salvo testo da escapare)"
done < <(find "$VIEWS" -name '*.blade.php')

# Complex logic belongs to controllers / viewController classes: queries fail, collection pipelines warn
while IFS= read -r file; do
  grep -qE '(::(where|query|find|findOrFail|all|first|whereIn|with)\(|DB::|->get\(\)|->paginate\()' "$file" \
    && fail blade-logic "$(rel "$file"): query nella Blade: va nel controller o in un viewController"
  grep -qE '(->(map|filter|groupBy|sortBy|sortByDesc|reduce|pluck|reject|flatMap)\(|collect\()' "$file" \
    && warn blade-logic "$(rel "$file"): trasformazione di collezione nella Blade: preparala nel controller"
done < <(find "$VIEWS" -name '*.blade.php')

done_checks check-views
