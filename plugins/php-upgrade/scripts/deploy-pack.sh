#!/usr/bin/env bash
# Prepara i pacchetti per PROD dal diff git mig/base..HEAD (solo SITE_PATHS).
#   deploy-pack.sh --prod-copy DIR --prod-dump FILE [--dry-run]
#     DIR  = copia fresca di PROD (prod-to-local), FILE = suo dump già verificato con backup-db.sh --verify
# Si ferma se i file da sostituire in PROD non sono identici a mig/base (PROD cambiato nel frattempo).
# Uscita in _migration/out/deploy-<data>/: deploy.tar.gz, deploy-manifest.txt (per deploy-push.sh), deploy-delete.txt,
#   rollback.tar.gz, rollback-delete.txt (per il deploy manuale), MANIFEST.txt
source "$(dirname "$0")/lib.sh"

PC=""; PD=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --prod-copy) PC=${2:-}; shift ;;
    --prod-dump) PD=${2:-}; shift ;;
    --dry-run) DRY=1 ;;
    *) die "argomento sconosciuto: $1" ;;
  esac; shift
done
banner "LOCAL -> pacchetto per PROD"
[ -d "$PC" ] || die "serve --prod-copy con la cartella scaricata da PROD (skill prod-pull-code)"
[ -f "$PD" ] && [ -f "$PD.verified" ] || die "serve --prod-dump con un dump di PROD verificato (backup-db.sh --verify)"
git -C "$ROOT" rev-parse -q --verify "$BASE_TAG" > /dev/null || die "manca il tag $BASE_TAG"
git_clean_or_die
bash "$PLUGIN_DIR/scripts/run-tests.sh" --static > /dev/null || die "i test statici non passano: niente pacchetto"

cd "$ROOT"
LIBDIRS=$(list_file "$MIG_DIR/libs.lock" | awk '{print $6}')
# KEEP_UNTRACKED (config e lingue che il sito scrive da sé, es. front/app/settings/) non va mai in PROD, anche se versionato:
# in PROD vale la loro versione (es. traduzioni aggiunte dall'admin)
mapfile -t EXCL < <(keep_excludes)
git diff --name-status --no-renames "$BASE_TAG" HEAD -- "${SITE_PATHS[@]}" "${EXCL[@]}" > "$OUT/changes.tmp"
[ -s "$OUT/changes.tmp" ] || die "nessuna modifica fra $BASE_TAG e HEAD"

# 1) PROD deve essere identico a mig/base sui file che tocchiamo
bad=0
while read -r st f; do
  if [ "$st" = A ]; then
    [ ! -e "$PC/$f" ] || { echo "DIVERSO: $f esiste già in PROD"; bad=1; }
  else
    [ -f "$PC/$f" ] || { echo "DIVERSO: $f manca in PROD"; bad=1; continue; }
    # --no-filters: byte grezzi (con core.autocrlf=true hash-object convertirebbe CRLF→LF e i file CRLF sembrerebbero cambiati)
    [ "$(git hash-object --no-filters "$PC/$f")" = "$(git rev-parse "$BASE_TAG:$f")" ] || { echo "DIVERSO: $f è cambiato in PROD dopo $BASE_TAG"; bad=1; }
  fi
done < "$OUT/changes.tmp"
[ $bad = 0 ] || die "PROD non coincide con $BASE_TAG: riallinea prima di procedere"
info "PROD coincide con $BASE_TAG sui $(wc -l < "$OUT/changes.tmp") file interessati"

D="$OUT/deploy-$(date +%Y%m%d-%H%M%S)"
[ $DRY = 1 ] && { cut -f1 "$OUT/changes.tmp" | sort | uniq -c; echo "(dry-run) nessun pacchetto creato"; exit 0; }
mkdir -p "$D"

# 2) Le librerie si sostituiscono intere: in PROD si cancella la cartella e si estrae quella nuova
in_lib() { local f=$1 l; for l in $LIBDIRS; do [[ "$f" == "$l"/* ]] && return 0; done; return 1; }
awk '$1!="D"{print $2}' "$OUT/changes.tmp" | while read -r f; do in_lib "$f" || echo "$f"; done > "$OUT/up.tmp"
awk '$1=="D"{print $2}' "$OUT/changes.tmp" | while read -r f; do in_lib "$f" || echo "$f"; done > "$D/deploy-delete.txt"
awk '$1!="A"{print $2}' "$OUT/changes.tmp" | while read -r f; do in_lib "$f" || echo "$f"; done > "$OUT/down.tmp"
awk '$1=="A"{print $2}' "$OUT/changes.tmp" | while read -r f; do in_lib "$f" || echo "$f"; done > "$D/rollback-delete.txt"
touched_libs=""
for l in $LIBDIRS; do grep -q "^[AMD]	$l/" "$OUT/changes.tmp" && touched_libs="$touched_libs $l"; done
for l in $touched_libs; do echo "$l/   (cartella intera)"; done | tee -a "$D/deploy-delete.txt" >> "$D/rollback-delete.txt"

pack() { # pack REF LISTA OUT LIBDIR... -> tar.gz con i file di REF (le librerie per cartella: righe di comando corte)
  local ref=$1 list=$2 out=$3 args; shift 3
  mapfile -t args < "$list"; args+=("$@")
  [ ${#args[@]} -gt 0 ] || return 0
  rm -rf "$OUT/pack"; mkdir -p "$OUT/pack"
  # autocrlf=false: i byte esatti del repo (su Windows git archive convertirebbe in CRLF), gli stessi SHA del manifest
  git -c core.autocrlf=false archive --format=tar "$ref" -- "${args[@]}" | tar -xf - -C "$OUT/pack"
  tar -czf "$out" -C "$OUT/pack" .
}
pack HEAD "$OUT/up.tmp" "$D/deploy.tar.gz" $touched_libs
# manifest per deploy-push.sh (remote/deploy.sh): SHA in mig/base dei file che cambiano + SHA di ogni file del pacchetto
{
  while read -r st f; do
    case "$st" in
      M|D) echo "BASE $st $(git cat-file blob "$BASE_TAG:$f" | sha256sum | cut -d' ' -f1) $f" ;;
      A)   echo "ADD $f" ;;
    esac
  done < "$OUT/changes.tmp"
  for l in $touched_libs; do echo "LIBDIR $l"; done
  (cd "$OUT/pack" && find . -type f | sed 's#^\./##' | sort | while read -r f; do echo "PKG $(sha256sum "$f" | cut -d' ' -f1) $f"; done)
} > "$D/deploy-manifest.txt"
awk '($1=="ADD"||$1=="LIBDIR") && NF!=2 || $1=="BASE" && NF!=4 || $1=="PKG" && NF!=3 {bad=1} END{exit !bad}' "$D/deploy-manifest.txt" &&
  die "percorsi con spazi nel pacchetto: non supportati da deploy-push (deploy manuale)"
pack "$BASE_TAG" "$OUT/down.tmp" "$D/rollback.tar.gz" $touched_libs
rm -rf "$OUT/pack" "$OUT"/*.tmp

{
  echo "Pacchetto: $(git log -1 --format='%h %s') vs $BASE_TAG   creato: $(date -Iseconds)"
  echo "Dump PROD verificato: $(cat "$PD.verified")"
  echo "Destinazione in PROD: $PROD_SITE"
  echo; echo "== File modificati (git diff --stat)"; git diff --stat "$BASE_TAG" HEAD -- "${SITE_PATHS[@]}" "${EXCL[@]}" | tail -n 30
  echo "Esclusi (restano quelli di PROD): ${KEEP_UNTRACKED[*]}"
  echo; echo "== SHA-256"; sha256sum "$D"/*.tar.gz | sed "s#$D/##"
} > "$D/MANIFEST.txt"
info "OK: pacchetti in $D"
tail -n 4 "$D/MANIFEST.txt"
