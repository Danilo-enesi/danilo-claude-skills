# _migration/config.sh — dati del progetto per il plugin php-upgrade (letto da script e guardia).
# Formato: variabili bash semplici e array `NOME=( ... )` su una o più righe (la guardia li legge con una regex).

PHP_PROD=7.0                      # PHP attuale in PROD: è il comportamento di riferimento (non la 7.4 locale)
PHP_FROM=7.4                      # PHP "vecchio" disponibile in locale (lint di compatibilità all'indietro)
PHP_TO=8.3                        # versione di arrivo

LOCAL_URL=https://www.example.test
PROD_URL=https://www.example.it
PROD_HOST=example.it              # dominio di PROD: richieste dirette bloccate dalla guardia

# Server di PROD (per prod-to-local e per le istruzioni di deploy). Il sito reale: attenzione ai link (www -> public_html)
PROD_SSH_USER=user
PROD_SSH_HOST=example.it
PROD_SSH_PORT=22
PROD_SITE=/home/user/public_html
PROD_PHP_HANDLER_FROM=ea-php70    # cPanel › MultiPHP Manager
PROD_PHP_HANDLER_TO=ea-php83
PROD_VAULT_PROFILE=example-login  # profilo del vault di prod-to-local con la password SSH (deploy-push/maintenance)
MAINT_PAGE=manutenzione.html      # pagina di manutenzione: sorgente in _migration/, pubblicata da maintenance.sh

# DB LOCALE (Dunebox)
DB_NAME=example_db
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASS=
MYSQL_VERSION=5.7

# File del sito versionati in git (rollback, deploy, controllo "albero pulito")
SITE_PATHS=(admin front index.php)
# Non versionati generati dal sito: il rollback non li cancella e non sporcano l'albero
KEEP_UNTRACKED=(admin/pers/ front/app/settings/)
# Percorsi che nessuno strumento di modifica può toccare (la guardia aggiunge _migration/ harness, .claude/, .git/, .htaccess)
PROTECTED=(
  admin/pers/ front/app/settings/ admin/public/
  admin/include/class/tcpdf/ admin/include/class/fpdi/ admin/include/class/phpmailer/
  admin/include/class/PHPExcel admin/include/class/smarty/ admin/lib/Google/ admin/lib/Facebook/
)
# Funzioni sacrificabili (non si sistemano): solo documentazione per le skill
SACRIFICABLE="import/export traduzioni (PHPExcel), API YouTube/Google, SDK Facebook"

# Facoltativi (default per Dunebox): PHP_FROM_BIN, PHP_TO_BIN, MYSQL_BIN, WEB_INI, PHP_LOG_DIR, DUNEBOX, BASE_TAG
