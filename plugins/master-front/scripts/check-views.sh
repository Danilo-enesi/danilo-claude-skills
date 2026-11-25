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

# Error and maintenance pages must exist (skill front-error-pages). Maintenance is rendered with no data before the
# shared content: no layout, facades or Blade components.
need_file error-pages "$VIEWS/pages/errors.blade.php" && ok error-pages "pages/errors.blade.php"
if need_file error-pages "$VIEWS/pages/maintenance.blade.php"; then
  # Blade comments may name what is forbidden (to explain why): only the code counts
  if perl -0pe 's/\{\{--.*?--\}\}//gs' "$VIEWS/pages/maintenance.blade.php" | grep -qE '@extends|(Front|Meta|Version|Websites|Dom)::|<x-'; then
    fail error-pages "pages/maintenance.blade.php usa layout, facade o componenti: senza dati deve stare in piedi da sola (solo traduzioni)"
  else
    ok error-pages "pages/maintenance.blade.php"
  fi
fi

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
  # a component prop bound to an array literal built from translations/routes/calls: the controller prepares it
  perl -0ne 'exit 1 if /\s:[\w.-]+\s*=\s*"\s*\[[^"]*(=>|\()/s' "$file" \
    || warn blade-logic "$(rel "$file"): array costruito nella vista e passato a un componente: preparalo nel controller e passa una variabile"
done < <(find "$VIEWS" -name '*.blade.php')

# Copied component: two views outside components/ sharing a run of 3 class attributes (same skeleton, other data).
# Bootstrap utility/grid classes and Blade expressions are dropped first, so only the block's own classes count.
# shortcut: matches exact class sequences only, misses copies with reordered or renamed classes (review stays manual)
find "$VIEWS" -name '*.blade.php' -not -path "$VIEWS/components/*" -not -path "$VIEWS/mail/*" -print0 \
  | xargs -0 -r perl -0ne '
    s/\{\{--.*?--\}\}//gs;
    my @c;
    while (/\sclass\s*=\s*"([^"]*)"/g) {
      (my $v = $1) =~ s/\{\{.*?\}\}|\{!!.*?!!\}|@\w+\(.*?\)//gs;
      my @t = grep { !/^(container(-\w+)?|row|col(-\w+)*|g[xy]?-\d|[mp][tbsexy]?-(\w+-)?\d|d-\S+|flex-\S+|justify-\S+|align-\S+|text-\S+|fw-\S+|w-\d+|h-\d+|order-\S+|position-\S+|visually-hidden|img-fluid|btn(-\S+)?|list-unstyled|mx-auto)$/ } split " ", $v;
      push @c, join(" ", @t) if @t;
    }
    my %seen;
    for my $i (0 .. $#c - 2) { my $k = join(" | ", @c[$i .. $i + 2]); print "$ARGV\t$k\n" unless $seen{$k}++ }' \
  | sort -t$'\t' -k2,2 -k1,1 -u \
  | awk -F'\t' '$2 == prev && $1 != pfile { print pfile "\t" $1 "\t" $2 } { prev = $2; pfile = $1 }' \
  | awk -F'\t' '!seen[$1 FS $2]++' \
  | while IFS=$'\t' read -r a b seq; do
      warn components-reuse "$(rel "$a") e $(rel "$b") hanno lo stesso scheletro (class: $seq): stesso componente con dati diversi, estrailo in components/"
    done

# Markup (rules/html-markup.md). Tags can span lines and Blade comments may quote bad examples, so perl reads the
# whole file without comments and prints "<line> <problem>" for each tag.
while IFS= read -r file; do
  while read -r line kind; do
    case "$kind" in
      img) fail html-markup "$(rel "$file"):$line <img> senza alt (alt=\"\" se decorativa)" ;;
      rel) fail html-markup "$(rel "$file"):$line link esterno senza rel=\"noopener noreferrer\"" ;;
      input:*) warn html-markup "$(rel "$file"):$line input type=\"text\" per un campo ${kind#input:}: usa il tipo giusto" ;;
      href) warn html-markup "$(rel "$file"):$line <a href=\"#\"> o javascript: per un'azione: usa <button type=\"button\">" ;;
      tabindex) warn html-markup "$(rel "$file"):$line campo del form senza tabindex (ordine logico di compilazione)" ;;
      h1) warn html-markup "$(rel "$file"):$line più di un <h1> nella stessa vista: uno solo per pagina" ;;
    esac
  done < <(perl -0ne '
    s/\{\{--.*?--\}\}/" " x length($&)/gse;            # blank comments, keep offsets
    sub at { my $p = shift; 1 + (substr($_, 0, $p) =~ tr/\n//) }
    while (/<img\b(?:[^>"]|"[^"]*")*>/gis) { my ($t, $p) = ($&, $-[0]); print at($p), " img\n" unless $t =~ /\salt\s*=|\s:alt\s*=/i }
    while (/<a\b(?:[^>"]|"[^"]*")*>/gis) {
      my ($t, $p) = ($&, $-[0]);
      next unless $t =~ /\shref\s*=\s*"(?:https?:)?\/\//i;
      print at($p), " rel\n" unless $t =~ /\srel\s*=\s*"[^"]*noopener[^"]*noreferrer|\srel\s*=\s*"[^"]*noreferrer[^"]*noopener/i;
    }
    while (/<input\b(?:[^>"]|"[^"]*")*>/gis) {
      my ($t, $p) = ($&, $-[0]);
      next unless $t =~ /\stype\s*=\s*"text"/i || $t !~ /\stype\s*=/i;
      next unless $t =~ /\sname\s*=\s*"([^"]*)"/i; my $n = lc $1;
      my $k = $n =~ /e-?mail/ ? "email" : $n =~ /(phone|tel|cell|mobile)/ ? "telefono" : $n =~ /(url|website|sito)/ ? "URL" : $n =~ /(date|data_|birth)/ ? "data" : "";
      print at($p), " input:$k\n" if $k;
    }
    # data-epp links (privacy/cookie policy) are the EPP library convention: href="#" is expected there
    while (/<a\b(?:[^>"]|"[^"]*")*>/gis) { my ($t, $p) = ($&, $-[0]); print at($p), " href\n" if $t =~ /\shref\s*=\s*"(?:#|javascript:[^"]*)"/i && $t !~ /\sdata-epp/i }
    # form fields (not hidden) and submit buttons inside a <form> need a tabindex
    while (/<form\b.*?<\/form>/gis) {
      my ($form, $start) = ($&, $-[0]);
      while ($form =~ /<(input|select|textarea|button)\b(?:[^>"]|"[^"]*")*>/gis) {
        my ($t, $p) = ($&, $start + $-[0]);
        next if $t =~ /\stype\s*=\s*"hidden"/i || ($1 =~ /button/i && $t =~ /\stype\s*=\s*"button"/i);
        print at($p), " tabindex\n" unless $t =~ /\stabindex\s*=/i;
      }
    }
    my $h1 = 0; while (/<h1\b/gi) { print at($-[0]), " h1\n" if ++$h1 == 2 }' "$file")
done < <(find "$VIEWS" -name '*.blade.php')

# One <main> per page, in the layout around @yield('content')
if [ -f "$VIEWS/layouts/main.blade.php" ]; then
  grep -q '<main' "$VIEWS/layouts/main.blade.php" && ok html-markup "<main> nel layout" || fail html-markup "layouts/main.blade.php senza <main> attorno al contenuto"
fi

done_checks check-views
