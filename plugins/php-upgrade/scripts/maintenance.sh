#!/usr/bin/env bash
# Pagina di manutenzione in PROD (503 per tutti tranne l'IP di questo PC).
#   maintenance.sh on [IP...]     carica _migration/manutenzione.html e aggiunge il blocco nel .htaccess di PROD
#   maintenance.sh off            toglie SOLO il blocco aggiunto (e la pagina, se l'ha creata lui)
#   maintenance.sh status
# L'IP escluso è quello con cui il server vede questo PC (SSH) + l'IP pubblico HTTP se diverso + gli IP dati.
# Le modifiche al .htaccess le fa remote/htaccess-maint.sh: solo righe tra marcatori, verificate byte per byte.
source "$(dirname "$0")/lib.sh"
source "$PLUGIN_DIR/scripts/prod-lib.sh"
cmd=${1:-}; shift || true
PAGE=${MAINT_PAGE:-manutenzione.html}
S=.php-upgrade/maintenance          # stato sul server, relativo alla home dell'utente SSH
banner PROD
prod_connect
case "$cmd" in
  on)
    [ -f "$MIG_DIR/$PAGE" ] || die "manca _migration/$PAGE: copiala da $PLUGIN_DIR/templates/manutenzione.html e adattala (nome, logo, colore)"
    extra=("$@")
    http_ip=$(curl -s -m 10 https://api.ipify.org || true)
    [[ "$http_ip" =~ ^[0-9.]+$ ]] && extra+=("$http_ip")
    pu_remote maintenance.sh prepare "$S"
    pu_put "$REMOTE_PU/htaccess-maint.sh" "$S/htaccess-maint.sh"
    pu_put "$MIG_DIR/$PAGE" "$S/$PAGE"
    pu_remote maintenance.sh on "$PROD_SITE" "$S" "$PAGE" "${extra[@]}"
    code=$(curl -s -o /dev/null -m 30 -w '%{http_code}' "$PROD_URL/" || echo 000)
    info "da questo PC la home risponde $code (atteso 200: l'IP è escluso). Da un'altra rete (telefono senza wifi) deve comparire la pagina di manutenzione."
    [ "$code" != 503 ] || warn "questo PC vede la 503: l'IP con cui esce in HTTP non è tra quelli esclusi (passalo: maintenance.sh on <IP>)" ;;
  off)
    pu_remote maintenance.sh off "$PROD_SITE" "$S" "$PAGE" ;;
  status)
    pu_remote maintenance.sh status "$PROD_SITE" "$S" ;;
  *) die "uso: maintenance.sh on [IP...] | off | status" ;;
esac
