#!/usr/bin/env bash
# assets/: theme Main folders, main/responsive/module split, media queries only in responsive.css, webp twins, libraries in lib/.
# Usage: check-assets.sh [project-root]
source "$(dirname "$0")/lib.sh" "$@"
M="$ASSETS/main"

for dir in css js lib icons images images/defaults images/icons; do
  if [ -d "$M/$dir" ]; then ok assets-structure "assets/main/$dir"; else fail assets-structure "manca assets/main/$dir/"; fi
done
need_file assets-structure "$M/css/main.css" && ok assets-structure "main.css"
need_file assets-structure "$M/css/responsive.css" && ok assets-structure "responsive.css"
need_file assets-structure "$M/js/main.js" && ok assets-structure "main.js"
if [ -f "$ASSETS/common/beers/beers.js" ]; then ok assets-structure "Beers"; else warn assets-structure "manca assets/common/beers/ (copiala da un progetto che la usa)"; fi

# Old names of the global stylesheet
[ -f "$M/css/style.css" ] && fail assets-structure "assets/main/css/style.css: il CSS globale si chiama main.css"

# Media queries only in responsive.css (lib/ and minified bundles excluded)
if [ -d "$M/css" ]; then
  while IFS= read -r file; do
    case "$(basename "$file")" in responsive.css|*.min.css) continue ;; esac
    grep -q '@media' "$file" && fail css-split "$(rel "$file"): @media fuori da responsive.css"
  done < <(find "$M/css" -name '*.css')
fi

# Third-party code outside lib/
for dir in css js; do
  [ -d "$M/$dir" ] || continue
  while IFS= read -r file; do
    case "$(basename "$file")" in base.min.*) continue ;; esac
    warn assets-structure "$(rel "$file"): sembra una libreria, va in assets/main/lib/<nome>/"
  done < <(find "$M/$dir" -maxdepth 1 \( -name '*.min.js' -o -name '*.min.css' -o -iname 'jquery*' -o -iname 'bootstrap*' -o -iname 'swiper*' -o -iname 'slick*' \))
done

# Every static raster image has its .webp twin
if [ -d "$M/images" ]; then
  while IFS= read -r img; do
    [ -f "${img%.*}.webp" ] || fail images-webp "$(rel "$img"): manca ${img##*/} in .webp"
  done < <(find "$M/images" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \))
  if [ -d "$M/images/defaults" ]; then
    while IFS= read -r img; do
      warn images-webp "$(rel "$img"): le default sono jpg + webp"
    done < <(find "$M/images/defaults" -type f -iname '*.png')
  fi
fi

done_checks check-assets
