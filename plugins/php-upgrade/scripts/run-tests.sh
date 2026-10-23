#!/usr/bin/env bash
# Esegue i test della migrazione.
#   run-tests.sh --static [--expect-red]   checks del progetto (_migration/checks.php) + G1 lint + A1 argomenti + A2 costanti
#   run-tests.sh --smoke                   prova in esecuzione (host locale su PHP_TO), solo front
# --expect-red: prima di migrare OGNI test deve fallire; uno che passa non dimostra nulla e viene segnalato
#   (A2 può passare già prima: se succede è solo informativo, non blocca).
source "$(dirname "$0")/lib.sh"
require_local

MODE=""; RED=0
for a in "$@"; do
  case "$a" in
    --static|--smoke) MODE=$a ;;
    --expect-red) RED=1 ;;
    *) die "argomento sconosciuto: $a" ;;
  esac
done
[ -n "$MODE" ] || die "uso: run-tests.sh --static [--expect-red] | --smoke"

if [ "$MODE" = --smoke ]; then
  grep -qE "\"php\": *\"${PHP_TO//./\\.}\"" "$ROOT/.dunebox/config.json" 2>/dev/null ||
    die "l'host locale non è su PHP $PHP_TO (.dunebox/config.json) o i servizi non sono stati riavviati"
  exec bash "$PLUGIN_DIR/scripts/smoke.sh" --target local
fi

export MIG_ROOT="$ROOT" MIG_PLUGIN="$PLUGIN_DIR"
# prefissi che A1/A2 non analizzano: harness, librerie di terzi (libs.lock + PROTECTED), file mai caricati (lint-ignore).
# Solo prefissi separati da | (niente regex con '/' iniziale: Git Bash riscrive le variabili che sembrano percorsi).
export MIG_SKIP_PREFIXES=$( { printf '%s\n' _migration/ .git/ vendor/ node_modules/
  list_file "$MIG_DIR/libs.lock" | awk '{print $6 "/"}'
  printf '%s\n' "${PROTECTED[@]}" | grep -iE '(class|lib)/'
  list_file "$MIG_DIR/lint-ignore.txt"; } | awk 'NF && !s[$0]++' | paste -sd'|')
P=("$PHP_TO_BIN" -d short_open_tag=1 -d memory_limit=1G)

out=""
[ -f "$MIG_DIR/checks.php" ] && out=$("${P[@]}" "$MIG_DIR/checks.php" || true)
if bash "$PLUGIN_DIR/scripts/lint.sh" to > "$OUT/lint.txt" 2>&1; then g=PASS; else g=FAIL; fi
if "${P[@]}" "$PLUGIN_DIR/scripts/scan-argcount.php" > "$OUT/argcount.txt" 2>&1; then a1=PASS; else a1=FAIL; fi
if "${P[@]}" "$PLUGIN_DIR/scripts/scan-undefconst.php" > "$OUT/undefconst.txt" 2>&1; then a2=PASS; else a2=FAIL; fi
out="${out:+$out
}G1   $g  tutto il sito compila in PHP $PHP_TO (esclusi lint-ignore.txt) -> $OUT/lint.txt
A1   $a1  nessuna chiamata con meno argomenti dei richiesti (7.1+; eccezioni in argcount-ignore.txt) -> $OUT/argcount.txt
A2   $a2  nessuna costante usata e mai definita (8.0+; eccezioni in const-ignore.txt) -> $OUT/undefconst.txt"
echo "$out"

if [ $RED = 1 ]; then
  useless=$(echo "$out" | awk '$2=="PASS" && $1!="A2"{print $1}' | paste -sd' ')
  [ -z "$useless" ] || die "questi test passano già PRIMA della migrazione, quindi non rilevano nulla: $useless"
  info "OK: tutti i test falliscono prima della migrazione (rilevano i problemi della SPEC)"
  exit 0
fi
! echo "$out" | grep -q ' FAIL '
