#!/usr/bin/env bash
# Lingue del front Master (front/app/settings/lang/<sito>/language_<lingua>.inc).
#   lang.sh missing [DIR]    voci presenti in una lingua e assenti in un'altra (= A3); DIR = altra radice, es. la copia
#                            di PROD (i file di lingua non viaggiano nel pacchetto: conta lo stato di PROD)
#   lang.sh sql              SQL idempotente per aggiungerle (valore segnaposto da tradurre); in PROD lo esegue l'utente
#                            (phpMyAdmin) e poi preme «Aggiorna i linguaggi» nell'admin
#   lang.sh regen [SITO]     rigenera i file dal DB LOCALE come «Aggiorna i linguaggi» (SITO = cartella; default: l'unica)
# Le scritture nel DB locale si fanno con un backup verificato prima (backup-db.sh) e solo su richiesta dell'utente.
source "$(dirname "$0")/lib.sh"
export MIG_ROOT="$ROOT" DB_HOST DB_PORT DB_USER DB_NAME
P=("$PHP_TO_BIN" -d short_open_tag=1)
case "${1:-}" in
  missing) MIG_ROOT=${2:-$ROOT} "${P[@]}" "$PLUGIN_DIR/scripts/scan-langs.php" ;;
  sql)     "${P[@]}" "$PLUGIN_DIR/scripts/scan-langs.php" --sql ;;
  regen)
    site=${2:-$(ls "$ROOT/front/app/settings/lang" 2>/dev/null)}
    [ "$(echo "$site" | grep -c .)" = 1 ] || die "più siti in front/app/settings/lang: indica quale (lang.sh regen SITO)"
    "${P[@]}" "$PLUGIN_DIR/scripts/lang-regen.php" "$site"
    git -C "$ROOT" diff --stat -- "front/app/settings/lang/$site" ;;
  *) die "uso: lang.sh missing | sql | regen [SITO]" ;;
esac
