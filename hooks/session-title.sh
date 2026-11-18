#!/usr/bin/env bash
# Nome della sessione con il prefisso dell'utente (la cartella di config: /srv/claude-config/danilo → DANILO).
# - SessionStart: <UTENTE>-<PROGETTO>-CLAUDE, dove il progetto è la cartella dopo la PRIMA cartella di iniziali
#   (es. /home/www/html/web/GHI/hpmotorrad/admin → HPMOTORRAD). Fuori da quella struttura non fa nulla.
# - UserPromptSubmit "/user-title FIX-ESPANGO": rinomina in <UTENTE>-FIX-ESPANGO.
# Se il nome è già usato da un'altra sessione dello stesso progetto (sottocartelle comprese) aggiunge -2, -3, ...
input=$(cat)
json() { grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"([^\"\\\\]|\\\\.)*\"" <<< "$input" | head -1 | sed -E 's/^[^:]*:[[:space:]]*"//; s/"$//'; }

event=$(json hook_event_name)
if [ "$event" = UserPromptSubmit ]; then
  [[ $(json prompt) =~ ^/(danilo-claude-skills:)?user-title[[:space:]]+([^[:space:]].*[^[:space:]]|[^[:space:]])[[:space:]]*$ ]] || exit 0
  name=${BASH_REMATCH[2]//[\"\\]/}
fi

prev=
root=
project=
IFS=/ read -ra parts <<< "$PWD"
for p in "${parts[@]}"; do
  root+="$p/"
  if [[ $prev =~ ^([A-Z]{3}|YZ|0-9)$ && -n $p ]]; then
    project=$p
    break
  fi
  prev=$p
done
if [ -z "$project" ]; then
  [ -n "$name" ] || exit 0
  root=$PWD
fi

transcript=$(json transcript_path | sed 's#\\\\#/#g')
projects=$(dirname "$(dirname "${transcript:-${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/x/y}")")
user=$(basename "$(dirname "$projects")")
# Fuori dal server la config è ~/.claude: lì l'utente è quello di sistema.
[ "$user" = .claude ] && user=$(whoami)
user=${user^^}

# Claude Code salva le sessioni in projects/<cwd con ogni carattere non alfanumerico sostituito da ->.
# shortcut: un progetto fratello "hpmotorrad-old" verrebbe contato insieme, va bene finché non succede.
root=${root%/}
# Git Bash su Windows: /c/Users/... → C:/Users/..., come lo vede Claude Code.
command -v cygpath >/dev/null && root=$(cygpath -m "$root")
san=$(sed 's/[^a-zA-Z0-9]/-/g' <<< "$root")
# Il nome di una sessione sta in <uuid>/custom-title.json (/rename) o, nelle versioni vecchie, nell'ultima riga custom-title del .jsonl.
taken=$(for f in "$projects/$san"/*.jsonl "$projects/$san"-*/*.jsonl; do
  [ -f "$f" ] && [ "$f" != "$transcript" ] || continue
  if [ -f "${f%.jsonl}/custom-title.json" ]; then
    grep -ohE '"customTitle"[[:space:]]*:[[:space:]]*"[^"]*"' "${f%.jsonl}/custom-title.json" | tail -1
  else
    grep -ohE '"customTitle"[[:space:]]*:[[:space:]]*"[^"]*"' "$f" | tail -1
  fi
done | sed -E 's/^.*:[[:space:]]*"//; s/"$//')

if [ -n "$name" ]; then base="$user-$name"; else base="$user-${project^^}-CLAUDE"; fi
title=$base
n=1
while grep -qxF "$title" <<< "$taken"; do
  n=$((n + 1))
  title="$base-$n"
done

if [ -n "$name" ]; then
  # Niente "block": con il prompt bloccato Claude Code scarta sessionTitle. Il modello conferma con una riga.
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","sessionTitle":"%s","additionalContext":"session-title hook: sesión renombrada a %s"}}\n' "$title" "$title"
else
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":"%s"}}\n' "$title"
fi
