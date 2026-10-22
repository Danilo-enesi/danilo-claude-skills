# Shared helpers for the prod-to-local scripts. Sourced, never run directly.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE_DIR="$SCRIPTS_DIR/../remote"
STATE_DIR="$HOME/.prod-to-local"
DEFAULT_PARENT="/c/devProjects"

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "== $*"; }

check_name() { [[ "$2" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid $1: '$2' (allowed: letters, digits, . _ -)"; }

# --- vault -------------------------------------------------------------------
vault() { powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(cygpath -w "$SCRIPTS_DIR/vault.ps1")" "$@"; }
vault_require() { vault has "$1" >/dev/null || die "vault profile '$1' not found: ask the user to run the prod-vault skill (set $1)"; }

# --- ssh / scp ---------------------------------------------------------------
# Call ssh_target once before remote/fetch. The password reaches ssh only through askpass.sh.
ssh_target() {
  R_USER=$1 R_HOST=$2 R_PORT=$3 R_PROFILE=$4
  check_name user "$R_USER"; check_name host "$R_HOST"; check_name profile "$R_PROFILE"
  [[ "$R_PORT" =~ ^[0-9]+$ ]] || die "invalid port: $R_PORT"
  export SSH_ASKPASS="$SCRIPTS_DIR/askpass.sh" SSH_ASKPASS_REQUIRE=force DISPLAY="${DISPLAY:-:0}" PROD_TO_LOCAL_PROFILE="$R_PROFILE"
  SSH_OPTS=(-o StrictHostKeyChecking=yes -o NumberOfPasswordPrompts=1 -o ConnectTimeout=20 -o ServerAliveInterval=30)
}

# remote <script> [args...]: runs remote/<script> on the server with bash, exactly as written in this repo.
remote() {
  local script=$1; shift
  ssh "${SSH_OPTS[@]}" -p "$R_PORT" "$R_USER@$R_HOST" "bash -s -- $(printf '%q ' "$@")" < "$REMOTE_DIR/$script"
}

# remote_with_secret <vault-profile> <script> [args...]: like remote, but the first stdin line is the secret (read into MYSQL_PWD).
remote_with_secret() {
  local profile=$1 script=$2; shift 2
  { vault get "$profile"; cat "$REMOTE_DIR/$script"; } |
    ssh "${SSH_OPTS[@]}" -p "$R_PORT" "$R_USER@$R_HOST" "IFS= read -r MYSQL_PWD && export MYSQL_PWD && exec bash -s -- $(printf '%q ' "$@")"
}

fetch() { scp -q "${SSH_OPTS[@]}" -P "$R_PORT" "$R_USER@$R_HOST:$1" "$2"; }

# --- ledger (one per job): what to undo if anything fails --------------------
# Entries, tab-separated:  local-dir <path> | local-file <path> | remote-file <user> <host> <port> <profile> <name>
job_start() {
  JOB=$1; check_name job "$JOB"
  mkdir -p "$STATE_DIR/jobs" "$STATE_DIR/tmp"
  LEDGER="$STATE_DIR/jobs/$JOB.ledger"
  touch "$LEDGER"
  trap 'rc=$?; if [ $rc -ne 0 ]; then echo "!! step failed (exit $rc): rolling back job $JOB" >&2; bash "$SCRIPTS_DIR/rollback.sh" --job "$JOB" >&2 || echo "!! rollback incomplete, see $LEDGER" >&2; fi' EXIT
}
ledger_add() { local IFS=$'\t'; echo "$*" >> "$LEDGER"; }
ledger_del() { local IFS=$'\t' line; line="$*"; grep -vxF -- "$line" "$LEDGER" > "$LEDGER.tmp" || true; mv "$LEDGER.tmp" "$LEDGER"; }

remote_name() { echo ".prod-to-local-$JOB-$(date +%Y%m%d%H%M%S)-$RANDOM$1"; }
