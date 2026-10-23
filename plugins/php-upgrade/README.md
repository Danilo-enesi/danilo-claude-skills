# php-upgrade

Porta un sito PHP legacy (Master 7 / phplib, PHP 7.x in produzione) a PHP 8.x a piccoli passi verificati: backup provati, test rossi prima di toccare il codice, patch minime, librerie sostituite intere, smoke del front e dell'admin, pacchetti per PROD con rollback.
Nato dalla migrazione di seychellesweb (PHP 7.0 → 8.3, ottobre 2026): ogni regola e ogni test vengono da un problema reale di quella migrazione.

## Come si usa
1. Nel progetto (repo git con il sito come in PROD): skill `mig-init` → `bash <plugin>/scripts/init.sh`, poi si compila `_migration/config.sh`.
2. Si segue `_migration/GUIA.md` (passi L0-L9 in locale, P0-P7 in produzione) con la skill d'ingresso `php-upgrade-workflow`.
3. Il backup di PROD usa il plugin `prod-to-local`.

## Skill
| Skill | Cosa fa |
|---|---|
| `php-upgrade-workflow` | punto d'ingresso: ordine dei passi, regole, come tenere l'utente informato senza rallentare |
| `mig-init` | crea `_migration/` (config, liste, SPEC, patch e check del core Master 7) |
| `mig-backup` | backup verificato del DB locale; backup di PROD con prod-to-local |
| `mig-test` | test statici (check del progetto, G1 lint, A1 argomenti, A2 costanti), smoke front/admin, confronto con PROD |
| `mig-apply-core` | host sul PHP nuovo (anche l'ini web di Dunebox) + patch approvate |
| `mig-update-lib` | sostituzione intera di una libreria (tcpdf, FPDI, PHPMailer…) e verifica delle API dei chiamanti |
| `mig-fix-runtime-error` | ogni FAIL/WARN: correzione minima su tutto il pattern, oppure nota (solo locale, sacrificabile, già prima) |
| `mig-report` | `_migration/REPORT.md` |
| `mig-deploy-prod` | P0-P7: ini di PROD, pacchetto, pagina di manutenzione 503, istruzioni all'utente, smoke in PROD |
| `mig-rollback` | annulla un passo o tutto, in LOCAL o in PROD |

## Script (`scripts/`, Git Bash dalla radice del progetto)
`env.sh` · `backup-db.sh` · `restore-db.sh` · `lint.sh from|to` · `patch.php` · `update-lib.sh` · `run-tests.sh --static|--smoke` · `smoke.sh` (`--admin-cookie`, `--target prod`) · `compare-prod.sh` (`--shots`) · `rollback.sh` · `deploy-pack.sh` · `init.sh`.
Test statici generici: **G1** lint, **A1** `scan-argcount.php` (meno argomenti: fatale da 7.1), **A2** `scan-undefconst.php` (costanti mai definite: fatali da 8.0). Il progetto aggiunge i suoi in `_migration/checks.php` (helper in `lib/checks-lib.php`).

## Guardia (`hooks/guard.py`)
Attiva solo nei progetti con `_migration/config.sh`; legge `PROTECTED` e `PROD_HOST` da lì. Blocca: scritture nei percorsi protetti e nell'harness, git che cambia lo stato, SQL che scrive, accesso diretto a PROD, `ssh` scritto a mano. Chiede il permesso per: smoke/confronto in PROD, rollback, restore del DB, pacchetto di deploy, script di prod-to-local.
Progettata per non rallentare: valuta i comandi per segmenti, ignora le stringhe tra apici e il testo dei messaggi di commit/heredoc, permette le letture (`git remote -v`, `git stash list`), la memoria di Claude, lo scratchpad, `GUIA.md` e `REPORT.md`. Pausa: l'utente crea `.claude/guard.off`.

## Test
```
bash plugins/php-upgrade/tests/selftest.sh
```
