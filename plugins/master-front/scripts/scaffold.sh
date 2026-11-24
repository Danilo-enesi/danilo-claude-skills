#!/usr/bin/env bash
# Creates the front scaffolding (Views + assets) from templates/. Never overwrites: an existing file is reported as SKIP.
# With --force it rewrites the template files and drops the old Views/base/, after copying everything it replaces
# into <root>/.scaffold-backup/<timestamp>/. Files outside the templates (pages, components, ...) are never touched.
# Usage: scaffold.sh [--force] [project-root]
FORCE=
if [ "$1" = --force ]; then FORCE=1; shift; fi
source "$(dirname "$0")/lib.sh" "$@"
T="$PLUGIN_DIR/templates"

if [ ! -d "$ROOT/private/front/Main" ]; then
  echo "STOP: $(rel "$ROOT/private/front/Main") non esiste. Non è un progetto Master Laravel Enesi (o il tema non è Main)."
  exit 1
fi

BACKUP="$ROOT/.scaffold-backup/$(date +%Y%m%d-%H%M%S)"
backup() { # backup <path>: copy a file or folder into the backup, keeping its path
  mkdir -p "$(dirname "$BACKUP/$(rel "$1")")" && cp -R "$1" "$BACKUP/$(rel "$1")"
}

copy() { # copy <template file> <destination>
  if [ -e "$2" ]; then
    if [ -z "$FORCE" ]; then echo "SKIP  $(rel "$2") (esiste già)"; return; fi
    if cmp -s "$1" "$2"; then echo "SAME  $(rel "$2")"; return; fi
    backup "$2" && cp "$1" "$2" && echo "OVER  $(rel "$2")"
    return
  fi
  mkdir -p "$(dirname "$2")" && cp "$1" "$2" && echo "NEW   $(rel "$2")"
}

while IFS= read -r file; do copy "$file" "$VIEWS/${file#"$T/views/"}"; done < <(find "$T/views" -type f ! -name '.gitkeep')
while IFS= read -r file; do copy "$file" "$ASSETS/${file#"$T/assets/"}"; done < <(find "$T/assets" -type f ! -name '.gitkeep')
while IFS= read -r file; do copy "$file" "$ROOT/private/front/Main/Components/${file#"$T/components/"}"; done < <(find "$T/components" -type f ! -name '.gitkeep')

# Empty folders of the convention (kept in git with a .gitkeep)
for dir in "$VIEWS/components" "$VIEWS/mail" \
  "$ASSETS/main/lib" "$ASSETS/main/icons" "$ASSETS/main/images/defaults" "$ASSETS/main/images/icons" \
  "$ASSETS/main/videos" "$ASSETS/main/documents" "$ASSETS/mail"; do
  if [ ! -d "$dir" ]; then mkdir -p "$dir" && touch "$dir/.gitkeep" && echo "NEW   $(rel "$dir")/"; fi
done

# The component class is useless until a provider registers it; the provider belongs to the project, so only report it.
PROVIDER=private/app/Providers/FrontServiceProvider.php
[ -f "$ROOT/$PROVIDER" ] || PROVIDER=private/app/Providers/AppServiceProvider.php
grep -rqsF "PictureWebP" "$ROOT/private/app" || echo "TODO  registra il componente in $PROVIDER, boot(): Blade::component('picture-web-p', \\Front\\Main\\Components\\PictureWebP::class);"
[ -f "$ASSETS/common/beers/beers.js" ] || echo "TODO  copia Beers (js, css, immagini) in assets/common/beers/ da un progetto che la usa (es. motoupgrade)"
if [ -d "$VIEWS/base" ]; then
  if [ -n "$FORCE" ]; then
    backup "$VIEWS/base" && rm -rf "$VIEWS/base" && echo "DEL   $(rel "$VIEWS/base")/ (struttura vecchia)"
  else
    echo "TODO  Views/base/ è la struttura vecchia: sposta header/footer in partials/, poi elimina base/"
  fi
fi
[ -d "$BACKUP" ] && echo "BACKUP $(rel "$BACKUP")/"
exit 0
