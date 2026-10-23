#!/usr/bin/env bash
# php -l su tutti i .php/.inc del sito (o sui percorsi dati), esclusi quelli in _migration/lint-ignore.txt.
#   lint.sh from|to [percorso...]      from = PHP_FROM (compatibilità all'indietro), to = PHP_TO
# Esce con 1 se almeno un file ha errori di sintassi.
source "$(dirname "$0")/lib.sh"
[ $# -ge 1 ] || die "uso: lint.sh from|to [percorso...]"
PHP=$(php_bin "$1"); shift
paths=("$@"); [ ${#paths[@]} -gt 0 ] || paths=("${SITE_PATHS[@]}")
cd "$ROOT"
ignore=$(list_file "$MIG_DIR/lint-ignore.txt" | paste -sd'|')

fails=0; n=0
while IFS= read -r f; do
  [ -f "$f" ] || continue  # tracciato in git ma rimosso (es. file eliminati da una nuova versione di libreria)
  [[ -n "$ignore" && "$f" =~ ^($ignore) ]] && continue
  n=$((n+1))
  # -n: default compilati (short_open_tag=On), come il sito si aspetta
  out=$("$PHP" -n -l "$f" 2>&1) || { echo "$out" | grep -v '^Errors parsing'; fails=$((fails+1)); }
done < <(git ls-files --cached --others --exclude-standard -- "${paths[@]}" | grep -E '\.(php|inc)$')

[ $n -gt 0 ] || die "nessun file da controllare in: ${paths[*]}"
echo "== lint PHP $("$PHP" -r 'echo PHP_VERSION;'): $n file, $fails con errori"
[ $fails = 0 ]
