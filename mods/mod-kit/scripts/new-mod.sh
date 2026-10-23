#!/usr/bin/env bash
# Crea un mod "deck" dal template: new-mod.sh <nome> "<Titolo>" [cartella-padre]
# Senza cartella-padre usa la cartella mod più recente in ~/.claude/dev-mods.
set -euo pipefail
name="${1:?uso: new-mod.sh <nome> \"<Titolo>\" [cartella-padre]}"
title="${2:-$name}"
[[ "$name" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]] || { echo "nome non valido: solo a-z 0-9 -" >&2; exit 1; }
kit="$(cd "$(dirname "$0")/.." && pwd)"
parent="${3:-$(ls -dt "$HOME"/.claude/dev-mods/*/ 2>/dev/null | head -1)}"
[ -n "$parent" ] || { echo "nessuna cartella dev-mods: passa la cartella-padre" >&2; exit 1; }
dest="${parent%/}/$name"
[ ! -e "$dest" ] || { echo "esiste già: $dest" >&2; exit 1; }
cp -r "$kit/template" "$dest"
# il titolo può contenere / e &: escapali per sed
esc_title=$(printf '%s' "$title" | sed 's/[\/&]/\\&/g')
find "$dest" -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.json' \) -exec sed -i "s/__NAME__/$name/g; s/__TITLE__/$esc_title/g" {} +
echo "$dest"
