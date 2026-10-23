#!/usr/bin/env bash
# Pagina di manutenzione in PROD. Gira sul server; maintenance.sh (locale) carica prima in STATEDIR
# htaccess-maint.sh e la pagina.
#   maintenance.sh prepare STATEDIR
#   maintenance.sh on      ROOT STATEDIR PAGE [IP...]   IP = quello del PC che lancia (da $SSH_CLIENT) + quelli dati
#   maintenance.sh off     ROOT STATEDIR PAGE
#   maintenance.sh status  ROOT STATEDIR
# La pagina si copia nella radice solo se non c'è (o è già identica); off la toglie solo se l'ha creata lui e non è cambiata.
set -euo pipefail
die() { echo "ERRORE: $*" >&2; exit 1; }
cmd=${1:-}; shift || true
root_ok() { [[ "$1" == /* ]] && [ -d "$1" ] && [ -f "$1/index.php" ] && [ -f "$1/.htaccess" ] || die "radice del sito non valida o senza .htaccess: $1"; }
page_ok() { [[ "$1" =~ ^[A-Za-z0-9._-]+\.html$ ]] || die "nome pagina non valido: $1"; }

case "$cmd" in
prepare) mkdir -p "${1:?STATEDIR}"; chmod 700 "$1" ;;
on)
  ROOT=${1:?}; S=${2:?}; PAGE=${3:?}; shift 3; root_ok "$ROOT"; page_ok "$PAGE"
  [ -f "$S/htaccess-maint.sh" ] && [ -f "$S/$PAGE" ] || die "mancano in $S lo script o la pagina (caricati da maintenance.sh)"
  me=${SSH_CLIENT%% *}; [ -n "$me" ] || die "SSH_CLIENT vuoto: non so l'IP di chi lancia"
  if [ ! -e "$ROOT/$PAGE" ]; then cp "$S/$PAGE" "$ROOT/$PAGE"; chmod 644 "$ROOT/$PAGE"; sha256sum "$ROOT/$PAGE" | cut -d' ' -f1 > "$S/page.created"; echo "pagina creata: $PAGE"
  elif cmp -s "$S/$PAGE" "$ROOT/$PAGE"; then echo "pagina già presente e identica: $PAGE"
  else echo "pagina $PAGE già presente con un altro contenuto: la lascio com'è"; fi
  bash "$S/htaccess-maint.sh" on "$ROOT/.htaccess" "$S" "$PAGE" "$me" "$@" ;;
off)
  ROOT=${1:?}; S=${2:?}; PAGE=${3:?}; root_ok "$ROOT"; page_ok "$PAGE"
  [ -f "$S/htaccess-maint.sh" ] || die "manca $S/htaccess-maint.sh"
  bash "$S/htaccess-maint.sh" off "$ROOT/.htaccess" "$S"
  if [ -f "$S/page.created" ] && [ -f "$ROOT/$PAGE" ] && [ "$(sha256sum "$ROOT/$PAGE" | cut -d' ' -f1)" = "$(cat "$S/page.created")" ]; then
    rm -f "$ROOT/$PAGE" "$S/page.created"; echo "pagina tolta: $PAGE (l'aveva creata php-upgrade)"
  else echo "pagina $PAGE lasciata (non creata da php-upgrade o modificata)"; fi ;;
status)
  ROOT=${1:?}; S=${2:?}; root_ok "$ROOT"
  [ -f "$S/htaccess-maint.sh" ] && bash "$S/htaccess-maint.sh" status "$ROOT/.htaccess" "$S" || echo "STATO=off (mai attivata)"
  echo "IP_CHE_LANCIA=${SSH_CLIENT%% *}" ;;
*) die "uso: maintenance.sh prepare|on|off|status ..." ;;
esac
