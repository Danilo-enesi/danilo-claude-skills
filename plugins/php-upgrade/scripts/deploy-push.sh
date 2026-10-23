#!/usr/bin/env bash
# Applica in PROD il pacchetto creato da deploy-pack.sh, via SSH con gli script fissi di remote/.
#   deploy-push.sh --pack _migration/out/deploy-AAAAMMGG-HHMMSS --dry-run   controlla che PROD = mig/base (nessuna scrittura)
#   deploy-push.sh --pack _migration/out/deploy-AAAAMMGG-HHMMSS             istantanea + applica + verifica SHA (rollback automatico)
#   deploy-rollback.sh --pack ...                                            rimette l'istantanea
# Il cambio di versione PHP (cPanel › MultiPHP Manager) resta all'utente.
source "$(dirname "$0")/lib.sh"
source "$PLUGIN_DIR/scripts/prod-lib.sh"
PACK=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in --pack) PACK=${2:-}; shift ;; --dry-run) DRY=1 ;; *) die "argomento sconosciuto: $1" ;; esac; shift
done
[ -f "$PACK/deploy.tar.gz" ] && [ -f "$PACK/deploy-manifest.txt" ] || die "serve --pack con deploy.tar.gz e deploy-manifest.txt (deploy-pack.sh)"
job=$(basename "$PACK"); [[ "$job" =~ ^deploy-[0-9-]+$ ]] || die "cartella del pacchetto inattesa: $job"
J=.php-upgrade/$job                 # sul server, relativo alla home
banner PROD
prod_connect
info "radice in PROD: $PROD_SITE   job: $J"
pu_remote deploy.sh prepare "$J"
pu_put "$PACK/deploy-manifest.txt" "$J/deploy-manifest.txt"
pu_remote deploy.sh check "$PROD_SITE" "$J/deploy-manifest.txt"
[ $DRY = 1 ] && { echo "(dry-run) nessuna modifica in PROD"; exit 0; }
pu_put "$PACK/deploy.tar.gz" "$J/deploy.tar.gz"
pu_remote deploy.sh apply "$PROD_SITE" "$J/deploy-manifest.txt" "$J/deploy.tar.gz" "$J"
info "Rollback, se servisse: bash $PLUGIN_DIR/scripts/deploy-rollback.sh --pack $PACK"
