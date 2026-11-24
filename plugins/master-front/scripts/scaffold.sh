#!/usr/bin/env bash
# Writes the front scaffolding from templates/, overwriting what differs. Files outside the templates are never touched.
#   --dry-run          only print what would happen (NEW / OVER / SAME / SKIP / DEL / TODO), write nothing
#   --backup           copy every file or folder it replaces or deletes into <root>/.scaffold-backup/<timestamp>/
#   --only <groups>    comma-separated optional groups: views, assets/main/css, assets/main/js, assets/mail (default: all)
# Always installed, whatever --only says: Beers (assets/common/beers/, loaded by head and scripts; skipped entirely if
# the project already has it), component classes
# (private/front/Main/Components/) and the empty convention folders of assets/main/ (lib, icons, images/defaults, images/icons, videos, documents).
# Usage: scaffold.sh [--dry-run] [--backup] [--only g1,g2] [project-root]
DRY= BACKUP_ON= ONLY="views,assets/main/css,assets/main/js,assets/mail"
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --backup) BACKUP_ON=1; shift ;;
    --only) ONLY="$2"; shift 2 ;;
    *) break ;;
  esac
done
source "$(dirname "$0")/lib.sh" "$@"
T="$PLUGIN_DIR/templates"

if [ ! -d "$ROOT/private/front/Main" ]; then
  echo "STOP: $(rel "$ROOT/private/front/Main") non esiste. Non è un progetto Master Laravel Enesi (o il tema non è Main)."
  exit 1
fi
for g in ${ONLY//,/ }; do
  case "$g" in views | assets/main/css | assets/main/js | assets/mail) ;; *) echo "STOP: gruppo sconosciuto '$g'"; exit 1 ;; esac
done
want() { [[ ",$ONLY," == *",$1,"* ]]; }
[ -n "$DRY" ] && echo "DRY-RUN: nessun file viene scritto"

BACKUP="$ROOT/.scaffold-backup/$(date +%Y%m%d-%H%M%S)"
backup() { # backup <path>: copy a file or folder into the backup, keeping its path
  [ -n "$BACKUP_ON" ] || return 0
  mkdir -p "$(dirname "$BACKUP/$(rel "$1")")" && cp -R "$1" "$BACKUP/$(rel "$1")"
}

copy() { # copy <template file> <destination>
  if [ -e "$2" ]; then
    if cmp -s "$1" "$2"; then echo "SAME  $(rel "$2")"; return; fi
    # Line counts tell real project work (1000 lines) from a stub about to be aligned (10 lines)
    local lines; lines="$(wc -l < "$2" | tr -d ' ') righe -> $(wc -l < "$1" | tr -d ' ')"
    [ -n "$DRY" ] || { backup "$2" && cp "$1" "$2"; } && echo "OVER  $(rel "$2") ($lines)"
    return
  fi
  [ -n "$DRY" ] || { mkdir -p "$(dirname "$2")" && cp "$1" "$2"; } && echo "NEW   $(rel "$2")"
}

folder() { # folder <dir>: an empty convention folder, kept in git with a .gitkeep
  [ -d "$1" ] && return
  [ -n "$DRY" ] || { mkdir -p "$1" && touch "$1/.gitkeep"; } && echo "NEW   $(rel "$1")/"
}

copy_tree() { # copy_tree <template dir> <destination dir>
  [ -d "$1" ] || return 0
  while IFS= read -r file; do copy "$file" "$2/${file#"$1/"}"; done < <(find "$1" -type f ! -name '.gitkeep')
}

# Optional groups
if want views; then
  copy_tree "$T/views" "$VIEWS"
  folder "$VIEWS/components"; folder "$VIEWS/mail"
  if [ -d "$VIEWS/base" ]; then
    files=$(find "$VIEWS/base" -type f | wc -l | tr -d ' ')
    [ -n "$DRY" ] || { backup "$VIEWS/base" && rm -rf "$VIEWS/base"; } && echo "DEL   $(rel "$VIEWS/base")/ (struttura vecchia, $files file)"
  fi
fi
want assets/main/css && copy_tree "$T/assets/main/css" "$ASSETS/main/css"
want assets/main/js && copy_tree "$T/assets/main/js" "$ASSETS/main/js"
want assets/mail && folder "$ASSETS/mail"

# Always installed
# Beers has no versioning and projects edit it in place: the only thing never overwritten once present.
if [ -d "$ASSETS/common/beers" ]; then
  echo "SKIP  $(rel "$ASSETS/common/beers")/ (esiste già: Beers si adatta al progetto, non si sovrascrive)"
else
  copy_tree "$T/assets/common/beers" "$ASSETS/common/beers"
fi
copy_tree "$T/components" "$ROOT/private/front/Main/Components"
for dir in lib icons images/defaults images/icons videos documents; do folder "$ASSETS/main/$dir"; done

# The component class is useless until a provider registers it; the provider belongs to the project, so only report it.
PROVIDER=private/app/Providers/FrontServiceProvider.php
[ -f "$ROOT/$PROVIDER" ] || PROVIDER=private/app/Providers/AppServiceProvider.php
grep -rqsF "PictureWebP" "$ROOT/private/app" || echo "TODO  registra il componente in $PROVIDER, boot(): Blade::component('picture-web-p', \\Front\\Main\\Components\\PictureWebP::class);"
[ -d "$BACKUP" ] && echo "BACKUP $(rel "$BACKUP")/"
exit 0
