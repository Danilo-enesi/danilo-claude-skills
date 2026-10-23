# Connessione a PROD per gli script di deploy e manutenzione. Si include con source dopo lib.sh.
# Credenziali: vault DPAPI e askpass del plugin prod-to-local (Claude non vede mai la password).
# Sul server si eseguono solo gli script di remote/ di questo plugin, mai comandi scritti a mano.
PTL_LIB="$PLUGIN_DIR/../prod-to-local/scripts/lib.sh"
[ -f "$PTL_LIB" ] || die "serve il plugin prod-to-local (stesso marketplace): $PTL_LIB"
_pu_die=$(declare -f die)
# shellcheck source=/dev/null
source "$PTL_LIB"            # ssh_target, vault_require, SSH_OPTS
eval "$_pu_die"              # i messaggi restano quelli di php-upgrade
REMOTE_PU="$PLUGIN_DIR/remote"

prod_connect() {
  : "${PROD_VAULT_PROFILE:?imposta PROD_VAULT_PROFILE in config.sh (profilo del vault di prod-to-local con la password SSH)}"
  vault_require "$PROD_VAULT_PROFILE"
  ssh_target "$PROD_SSH_USER" "$PROD_SSH_HOST" "$PROD_SSH_PORT" "$PROD_VAULT_PROFILE"
  [[ "$PROD_SITE" == /* ]] || die "PROD_SITE deve essere un percorso assoluto (la radice reale, non il link www)"
}
# pu_remote <script> [args...]: esegue remote/<script> sul server con bash, esattamente com'è nel plugin
pu_remote() { local s=$1; shift; ssh "${SSH_OPTS[@]}" -p "$R_PORT" "$R_USER@$R_HOST" "bash -s -- $(printf '%q ' "$@")" < "$REMOTE_PU/$s"; }
# pu_put <file locale> <percorso remoto relativo alla home>
pu_put() { scp -q "${SSH_OPTS[@]}" -P "$R_PORT" "$1" "$R_USER@$R_HOST:$2"; }
