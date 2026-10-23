#!/usr/bin/env bash
# Applica in PROD il pacchetto di deploy-pack.sh, con istantanea e rollback. Gira sul server (bash, coreutils, tar).
#   deploy.sh prepare  JOBDIR                   crea la cartella del job (relativa alla home)
#   deploy.sh check    ROOT MANIFEST            PROD è identico a mig/base su ogni file che cambia? (nessuna scrittura)
#   deploy.sh apply    ROOT MANIFEST TAR JOBDIR check + istantanea + applica + verifica; se qualcosa fallisce torna indietro
#   deploy.sh rollback ROOT JOBDIR              rimette l'istantanea (file modificati/cancellati, cartelle librerie) e toglie i file aggiunti
#   deploy.sh status   JOBDIR
# MANIFEST (da deploy-pack.sh), una voce per riga, campi separati da spazio:
#   BASE M|D <sha256 in mig/base> <percorso>   file modificato / cancellato
#   ADD <percorso>                              file nuovo (non deve esistere)
#   LIBDIR <cartella>                           libreria sostituita intera (si cancella prima di estrarre)
#   PKG <sha256> <percorso>                     ogni file del pacchetto, verificato dopo l'estrazione
set -euo pipefail
die() { echo "ERRORE: $*" >&2; exit 1; }
info() { echo "== $*"; }
cmd=${1:-}; shift || true

safe() { [[ "$1" =~ ^[A-Za-z0-9._/@+-]+$ && "$1" != /* && "$1" != *..* ]] || die "percorso non ammesso nel manifest: $1"; }
root_ok() { [[ "$1" == /* ]] && [ -d "$1" ] && [ -f "$1/index.php" ] || die "radice del sito non valida: $1"; }
load() { # manifest -> array
  BASE_M=(); BASE_D=(); SHA=(); ADDS=(); LIBS=(); PKG=()
  while read -r kind a b c; do
    case "$kind" in
      BASE) safe "$c"; [ "$a" = M ] && BASE_M+=("$c") || BASE_D+=("$c"); SHA+=("$b $c") ;;
      ADD)  safe "$a"; ADDS+=("$a") ;;
      LIBDIR) safe "$a"; LIBS+=("$a") ;;
      PKG)  safe "$b"; PKG+=("$a $b") ;;
      ''|'#'*) ;;
      *) die "voce sconosciuta nel manifest: $kind" ;;
    esac
  done < "$1"
  [ ${#PKG[@]} -gt 0 ] || die "manifest senza file del pacchetto"
}
in_lib() { local l; for l in "${LIBS[@]}"; do [[ "$1" == "$l"/* ]] && return 0; done; return 1; }
check() { # $1 = ROOT; stampa le differenze, exit 1 se ce ne sono
  local bad=0 s p
  for x in "${SHA[@]}"; do s=${x%% *}; p=${x#* }
    if [ ! -f "$1/$p" ]; then echo "DIVERSO: manca in PROD $p"; bad=1
    elif [ "$(sha256sum "$1/$p" | cut -d' ' -f1)" != "$s" ]; then echo "DIVERSO: cambiato in PROD dopo mig/base $p"; bad=1; fi
  done
  for p in "${ADDS[@]}"; do in_lib "$p" || [ ! -e "$1/$p" ] || { echo "DIVERSO: esiste già in PROD $p"; bad=1; }; done
  return $bad
}
verify_pkg() { local s p bad=0
  for x in "${PKG[@]}"; do s=${x%% *}; p=${x#* }
    [ -f "$1/$p" ] && [ "$(sha256sum "$1/$p" | cut -d' ' -f1)" = "$s" ] || { echo "NON CORRISPONDE dopo l'estrazione: $p"; bad=1; }
  done; return $bad
}
restore() { # $1 = ROOT, $2 = JOBDIR
  local p
  for l in "${LIBS[@]}"; do rm -rf "${1:?}/$l"; done
  for p in "${ADDS[@]}"; do in_lib "$p" || rm -f "$1/$p"; done
  tar -xzf "$2/before.tgz" -C "$1"
  check "$1" > "$2/rollback-check.txt" || { cat "$2/rollback-check.txt"; die "rollback incompleto: vedi $2"; }
  echo rolledback > "$2/state"
}

case "$cmd" in
prepare)
  J=${1:?JOBDIR}; safe "$J"; mkdir -p "$J"; chmod 700 "$J" ;;
check)
  ROOT=${1:?ROOT}; M=${2:?MANIFEST}; root_ok "$ROOT"; load "$M"
  if check "$ROOT"; then info "PROD coincide con mig/base su ${#SHA[@]} file modificati/cancellati; ${#ADDS[@]} nuovi; librerie intere: ${LIBS[*]:-nessuna}"
  else die "PROD non coincide con mig/base: niente deploy"; fi ;;

apply)
  ROOT=${1:?ROOT}; M=${2:?MANIFEST}; TAR=${3:?TAR}; J=${4:?JOBDIR}; root_ok "$ROOT"; load "$M"
  [ -f "$TAR" ] || die "pacchetto non trovato: $TAR"
  [ ! -f "$J/state" ] || die "job già usato ($(cat "$J/state")): per riapplicare crea un nuovo pacchetto"
  mkdir -p "$J"; cp "$M" "$J/manifest.txt"
  check "$ROOT" || die "PROD non coincide con mig/base: niente deploy"
  info "1/4 istantanea di ciò che cambia -> $J/before.tgz"
  snap=(); for p in "${BASE_M[@]}" "${BASE_D[@]}"; do in_lib "$p" || snap+=("$p"); done
  for l in "${LIBS[@]}"; do [ -e "$ROOT/$l" ] && snap+=("$l"); done
  tar -czf "$J/before.tgz" -C "$ROOT" "${snap[@]}"
  tar -tzf "$J/before.tgz" > /dev/null || die "istantanea illeggibile: niente deploy"
  echo applying > "$J/state"
  trap 'rc=$?; if [ $rc -ne 0 ] && [ "$(cat "$J/state")" = applying ]; then echo "!! errore durante il deploy: ripristino l istantanea" >&2; restore "$ROOT" "$J" >&2 && echo "!! ripristino fatto: PROD è come prima" >&2; fi' EXIT
  info "2/4 cancellazione delle librerie sostituite intere e dei file tolti"
  for l in "${LIBS[@]}"; do rm -rf "${ROOT:?}/$l"; done
  for p in "${BASE_D[@]}"; do in_lib "$p" || rm -f "$ROOT/$p"; done
  info "3/4 estrazione (tar -x)"
  tar -xzf "$TAR" -C "$ROOT"
  info "4/4 verifica SHA-256 di ${#PKG[@]} file"
  verify_pkg "$ROOT"
  echo applied > "$J/state"
  info "OK: deploy applicato. Rollback: deploy.sh rollback $ROOT $J" ;;

rollback)
  ROOT=${1:?ROOT}; J=${2:?JOBDIR}; root_ok "$ROOT"
  [ -f "$J/before.tgz" ] && [ -f "$J/manifest.txt" ] || die "istantanea non trovata in $J"
  [ "$(cat "$J/state")" = applied ] || [ "$(cat "$J/state")" = applying ] || die "stato del job: $(cat "$J/state"), niente da annullare"
  load "$J/manifest.txt"; restore "$ROOT" "$J"
  info "OK: PROD riportato com'era prima del deploy (file verificati con mig/base)" ;;

status)
  J=${1:?JOBDIR}; [ -f "$J/state" ] && echo "STATO=$(cat "$J/state")" || echo "STATO=nessuno" ;;
*) die "uso: deploy.sh check|apply|rollback|status ..." ;;
esac
