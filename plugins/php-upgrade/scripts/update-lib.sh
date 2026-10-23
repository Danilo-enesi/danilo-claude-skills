#!/usr/bin/env bash
# Sostituisce INTERA una libreria di terzi con la versione fissata in _migration/libs.lock. Non si modifica a mano.
#   update-lib.sh NOME [--download] [--apply]
# Senza --apply è un dry-run. --download scarica lo zip (dopo l'ok dell'utente alla versione) e, se lo SHA-256
# non è ancora nel lock, lo stampa e si ferma. Se qualcosa fallisce dopo lo scambio, la cartella originale torna al suo posto.
# libs.lock: nome versione url sha256 cartella-nello-zip destinazione da-tenere(csv|-) da-escludere(csv|-)
#   da-tenere accetta glob relativi alla destinazione (es. fonts/opensans*).
source "$(dirname "$0")/lib.sh"

NAME=""; DL=0; APPLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --download) DL=1 ;;
    --apply) APPLY=1 ;;
    -*) die "argomento sconosciuto: $1" ;;
    *) NAME=$1 ;;
  esac; shift
done
banner LOCAL
[ -n "$NAME" ] || die "uso: update-lib.sh NOME [--download] [--apply]"
read -r _ VER URL SHA SUB DEST KEEP EXCL <<< "$(grep -E "^$NAME " "$MIG_DIR/libs.lock" || true)"
[ -n "${DEST:-}" ] || die "libreria '$NAME' non presente (o incompleta) in libs.lock"
[ -d "$ROOT/$DEST" ] || die "cartella di destinazione inesistente: $DEST"

ZIP="$OUT/dl/$NAME-$VER.zip"
mkdir -p "$OUT/dl"
if [ ! -f "$ZIP" ]; then
  [ $DL = 1 ] || die "manca $ZIP: rilancia con --download dopo l'ok dell'utente"
  info "download $URL"
  curl -fsSL -o "$ZIP" "$URL" || { rm -f "$ZIP"; die "download fallito"; }
fi
got=$(sha256sum "$ZIP" | cut -d' ' -f1)
if [ "$SHA" = "-" ]; then die "SHA-256 non fissato in libs.lock. Valore dello zip scaricato: $got (registralo dopo l'ok dell'utente)"; fi
[ "$got" = "$SHA" ] || { rm -f "$ZIP"; die "SHA-256 diverso da libs.lock: $got (zip cancellato)"; }

STAGE="$OUT/stage/$NAME"; rm -rf "$STAGE"; mkdir -p "$STAGE"
unzip -q "$ZIP" -d "$STAGE/zip"
[ -d "$STAGE/zip/$SUB" ] || die "cartella '$SUB' non trovata nello zip"
NEW="$STAGE/new"; cp -r "$STAGE/zip/$SUB" "$NEW"
[ "$EXCL" = "-" ] || for e in ${EXCL//,/ }; do rm -rf "${NEW:?}/$e"; done
if [ "$KEEP" != "-" ]; then
  cd "$ROOT/$DEST"
  for k in ${KEEP//,/ }; do
    matches=( $k )   # glob espanso nella cartella attuale della libreria
    [ -e "${matches[0]}" ] || die "file da tenere inesistente nella versione attuale: $DEST/$k"
    for m in "${matches[@]}"; do mkdir -p "$(dirname "$NEW/$m")"; cp -r "$m" "$NEW/$m"; done
  done
  cd "$ROOT"
fi
# File nostri sopra la libreria (es. lo shim class.phpmailer.php): _migration/files/lib-NOME/
[ -d "$MIG_DIR/files/lib-$NAME" ] && cp -r "$MIG_DIR/files/lib-$NAME/." "$NEW/"

info "$NAME -> $VER in $DEST (tenuti: $KEEP, esclusi: $EXCL)"
echo "   file attuali: $(find "$ROOT/$DEST" -type f | wc -l)   nuovi: $(find "$NEW" -type f | wc -l)"
[ $APPLY = 1 ] || { echo "(dry-run) nessuna modifica. Rilancia con --apply."; exit 0; }

OLD="$STAGE/old"
mv "$ROOT/$DEST" "$OLD"
restore() { rm -rf "${ROOT:?}/$DEST"; mv "$OLD" "$ROOT/$DEST"; die "$1 (cartella originale ripristinata)"; }
cp -r "$NEW" "$ROOT/$DEST" || restore "copia fallita"
bash "$PLUGIN_DIR/scripts/lint.sh" to "$DEST" > "$STAGE/lint.txt" 2>&1 || { cat "$STAGE/lint.txt"; restore "la nuova versione non compila in PHP $PHP_TO"; }
rm -rf "$OLD"
info "OK: $NAME aggiornata (nell'indice git). Diff:"
git -C "$ROOT" add -A -- "$DEST" && git -C "$ROOT" diff --cached --stat -- "$DEST" | tail -n 3
info "Ricorda: L1 controlla solo versione e compilazione. Verifica le API usate dai chiamanti (skill mig-update-lib)."
