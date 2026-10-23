#!/usr/bin/env bash
# Annulla in PROD il deploy di deploy-push.sh rimettendo l'istantanea salvata sul server (file verificati con mig/base).
#   deploy-rollback.sh --pack _migration/out/deploy-AAAAMMGG-HHMMSS
# Prima o dopo, l'utente rimette la versione PHP vecchia in cPanel (PROD_PHP_HANDLER_FROM).
source "$(dirname "$0")/lib.sh"
source "$PLUGIN_DIR/scripts/prod-lib.sh"
PACK=""
while [ $# -gt 0 ]; do case "$1" in --pack) PACK=${2:-}; shift ;; *) die "argomento sconosciuto: $1" ;; esac; shift; done
job=$(basename "${PACK:?--pack}"); [[ "$job" =~ ^deploy-[0-9-]+$ ]] || die "cartella del pacchetto inattesa: $job"
banner PROD
prod_connect
pu_remote deploy.sh rollback "$PROD_SITE" ".php-upgrade/$job"
