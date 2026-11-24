#!/usr/bin/env bash
# Looks a library up in the list of cdn.ene.si (data/cdn-plugins.md) and prints only its URL, versions and, when it
# must wait for cookie consent, the EPP warning, so the whole list never has to be read.
#   cdn.sh <name>    exact name (case-insensitive) or, failing that, every plugin whose name contains it
#   cdn.sh           only the plugin names, one line
# Exit 1 when nothing matches: the library is not on the CDN.
LIST="$(dirname "$0")/../data/cdn-plugins.md"
BASE="//cdn.ene.si"

# Table rows "| name | versions | block |" -> "name<TAB>v1, v2<TAB>SI|NO" (backticks dropped; no version -> "-",
# because read with a tab IFS would swallow an empty field)
rows() {
  grep -E '^\| [^|]+ \| [^|]+ \| [^|]+ \|$' "$LIST" | grep -vE '^\| (Plugin|---)' \
    | sed -E 's/^\| *([^|]*[^| ]) *\| *([^|]*[^| ]) *\| *([^|]*[^| ]) *\|$/\1\t\2\t\3/; s/`//g' \
    | awk -F'\t' '{ v = ($2 ~ /^senza versione/) ? "-" : $2; print $1 "\t" v "\t" toupper($3) }'
}

show() { # show <name> <versions> <block>
  if [ "$2" = - ]; then
    printf '%s\n  url: %s/%s/ (senza versione: file sciolti)\n' "$1" "$BASE" "$1"
  else
    latest="${2##*, }"
    printf '%s\n  url: %s/%s/%s/ (ultima)\n  versioni: %s\n' "$1" "$BASE" "$1" "$latest" "$2"
  fi
  if [ "$3" = SI ]; then
    printf '  blocco preventivo: SI - va bloccato con EPP fino al consenso cookie; lo fa l'"'"'operatore, tu lascia solo un TODO\n'
  fi
}

if [ $# -eq 0 ]; then
  rows | cut -f1 | paste -sd' ' -
  exit 0
fi

query=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
exact=$(rows | awk -F'\t' -v q="$query" 'tolower($1) == q')
matches=${exact:-$(rows | awk -F'\t' -v q="$query" 'index(tolower($1), q)')}

if [ -z "$matches" ]; then
  echo "NON IN CDN: $1 (cdn.sh senza argomenti elenca i nomi)"
  exit 1
fi
while IFS=$'\t' read -r name versions block; do show "$name" "$versions" "$block"; done <<< "$matches"
