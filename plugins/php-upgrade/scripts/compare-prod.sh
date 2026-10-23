#!/usr/bin/env bash
# Confronta il testo visibile delle stesse pagine in LOCAL e in PROD (solo GET). Sola lettura.
#   compare-prod.sh --confirm-prod [lista]     lista di percorsi (default: _migration/urls-compare.txt)
#   compare-prod.sh --confirm-prod --shots     in più screenshot Chrome headless e pixel diversi (ImageMagick)
# Diff e immagini in out/compare/. Differenze tipiche solo in LOCAL Windows: mesi in inglese (manca il locale it_IT).
source "$(dirname "$0")/lib.sh"

CONFIRM=0; SHOTS=0; LIST="$MIG_DIR/urls-compare.txt"
for a in "$@"; do
  case "$a" in
    --confirm-prod) CONFIRM=1 ;;
    --shots) SHOTS=1 ;;
    -*) die "argomento sconosciuto: $a" ;;
    *) LIST=$a ;;
  esac
done
[ $CONFIRM = 1 ] || die "legge da PROD: serve --confirm-prod (solo dopo l'ok dell'utente)"
[ -f "$LIST" ] || die "lista non trovata: $LIST"
banner PROD
D="$OUT/compare"; mkdir -p "$D"
CHROME=${CHROME:-"/c/Program Files/Google/Chrome/Application/chrome.exe"}
[ $SHOTS = 0 ] || [ -x "$CHROME" ] || die "Chrome non trovato: imposta CHROME in config.sh"

txt() { perl -0pe 's/<(script|style)\b.*?<\/\1>//gis; s/<[^>]+>/\n/g; s/&nbsp;/ /g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$' || true; }
shot() { "$CHROME" --headless=new --disable-gpu --hide-scrollbars --ignore-certificate-errors --window-size=1440,4000 \
  --virtual-time-budget=10000 --user-data-dir="$D/chrome-profile" --screenshot="$(cygpath -w "$2")" "$1" 2>/dev/null; }

while read -r p; do
  n=$(echo "$p" | tr '/' '_')
  l=$(curl -sk -m 60 -o "$D/L$n.html" -w '%{http_code}' "$LOCAL_URL$p" || echo 000)
  r=$(curl -s  -m 60 -o "$D/P$n.html" -w '%{http_code}' "$PROD_URL$p" || echo 000)
  txt < "$D/L$n.html" | sed "s#${LOCAL_URL#https://}#${PROD_URL#https://}#g" > "$D/L$n.txt"
  txt < "$D/P$n.html" > "$D/P$n.txt"
  diff "$D/P$n.txt" "$D/L$n.txt" > "$D/diff$n.txt" || true
  line=$(printf "%-60s local=%s prod=%s righe_diverse=%s" "$p" "$l" "$r" "$(grep -c '^[<>]' "$D/diff$n.txt" || true)")
  if [ $SHOTS = 1 ]; then
    shot "$LOCAL_URL$p" "$D/L$n.png"; shot "$PROD_URL$p" "$D/P$n.png"
    ae=$(magick compare -metric AE -fuzz 8% "$D/P$n.png" "$D/L$n.png" "$D/D$n.png" 2>&1 || true)
    line="$line pixel_diversi=${ae%% *}"
  fi
  echo "$line"
done < <(list_file "$LIST")
