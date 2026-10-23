# Funzioni comuni degli script di php-upgrade. Si include con source, non si esegue.
# Gli script si lanciano dalla radice del progetto; i dati del progetto stanno in _migration/config.sh.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# cd + pwd: percorso POSIX (/c/...). Con "C:/..." GNU tar crede che "C:" sia un host remoto.
ROOT="$(cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && pwd)"
MIG_DIR="$ROOT/_migration"
OUT="$MIG_DIR/out"

die()  { echo "ERRORE: $*" >&2; exit 1; }
info() { echo "== $*"; }
warn() { echo "ATTENZIONE: $*" >&2; }

[ -f "$MIG_DIR/config.sh" ] || die "manca $MIG_DIR/config.sh: lancia prima 'bash $PLUGIN_DIR/scripts/init.sh' (skill mig-init)"
# shellcheck source=/dev/null
source "$MIG_DIR/config.sh"
mkdir -p "$OUT"

# Default per Dunebox (Windows); il progetto può ridefinirli in config.sh
DUNEBOX=${DUNEBOX:-/c/dunebox}
php_dir() { ls -d "$DUNEBOX"/system/apps/php/php-"$1".*-x64 2>/dev/null | sort -V | tail -1; }
PHP_FROM_BIN=${PHP_FROM_BIN:-$(php_dir "$PHP_FROM")/php.exe}
PHP_TO_BIN=${PHP_TO_BIN:-$(php_dir "$PHP_TO")/php.exe}
MYSQL_BIN=${MYSQL_BIN:-$(ls -d "$DUNEBOX"/system/apps/mysql/mysql-"${MYSQL_VERSION:-5.7}".*/bin 2>/dev/null | sort -V | tail -1)}
WEB_INI=${WEB_INI:-/c/devConfig/php/php-$PHP_TO.ini}       # il web server di Dunebox NON usa il php.ini del CLI
PHP_LOG_DIR=${PHP_LOG_DIR:-/c/devLogs}
DB_VERIFY=${DB_VERIFY:-${DB_NAME}_verify}                    # unico DB che gli script possono cancellare
DB_ARGS=(-h"${DB_HOST:-127.0.0.1}" -P"${DB_PORT:-3306}" -u"${DB_USER:-root}")
export MYSQL_PWD=${DB_PASS:-}                                # credenziali del MySQL LOCALE
BASE_TAG=${BASE_TAG:-mig/base}

php_bin() {
  case "$1" in
    from) echo "$PHP_FROM_BIN" ;;
    to)   echo "$PHP_TO_BIN" ;;
    *)    die "versione PHP non valida: '$1' (ammesse: from, to)" ;;
  esac
}

# Gli script girano solo sul PC: in produzione si caricano file, non si eseguono script.
require_local() {
  [ -x "$PHP_TO_BIN" ] || die "PHP $PHP_TO non trovato ($PHP_TO_BIN): imposta PHP_TO_BIN in config.sh"
  [ -x "$PHP_FROM_BIN" ] || die "PHP $PHP_FROM non trovato ($PHP_FROM_BIN): imposta PHP_FROM_BIN in config.sh"
}

banner() {
  echo "############################################"
  echo "#  AMBIENTE: $1"
  [ "$1" = PROD ] && echo "#  $PROD_URL  (solo letture HTTP)"
  [ "$1" = LOCAL ] && echo "#  $LOCAL_URL"
  echo "############################################"
}

# pathspec git che esclude i file non versionati che il sito genera da sé (KEEP_UNTRACKED)
keep_excludes() { local k; for k in "${KEEP_UNTRACKED[@]}"; do printf ':(exclude)%s\n' "$k"; done; }

git_clean_or_die() {
  local ex; mapfile -t ex < <(keep_excludes)
  [ -z "$(git -C "$ROOT" status --porcelain -- "${SITE_PATHS[@]}" _migration "${ex[@]}")" ] ||
    die "ci sono modifiche non committate nel sito o in _migration: committa o fai rollback prima di continuare"
}

# righe utili di un file di lista (senza commenti e righe vuote)
list_file() { [ -f "$1" ] && grep -vE '^\s*(#|$)' "$1" | sed 's/\s*#.*//' || true; }
