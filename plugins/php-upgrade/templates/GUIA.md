# Guida — migrazione PHP (plugin php-upgrade)

Comandi in **Git Bash** dalla radice del progetto, con `PU=C:/Users/danilo/Dev/danilo-claude-skills/plugins/php-upgrade/scripts`.
Dati del progetto in `_migration/config.sh`. In PROD non si esegue nessuno script: l'utente carica file e cambia la versione PHP.
Riferimento del comportamento: **PROD (`PHP_PROD`)**, non il PHP vecchio locale. Ogni passo = un commit.

## LOCAL
| # | Passo | Comando / azione | Fatto quando |
|---|---|---|---|
| L0 | Ambiente | `bash $PU/env.sh`. Se il CLI nuovo non ha `php.ini`: crearlo con **solo** `extension_dir` (assoluto) e `extension=curl/gd/mbstring/mysqli/openssl` | nessuna estensione mancante, nessun avviso sull'ini |
| L1 | Backup DB | `bash $PU/backup-db.sh` | `….verified` creato |
| L2 | Riferimento + test rossi | `urls.txt` da `urls-from-routes.php` (tutte le lingue); sito sul PHP vecchio: `bash $PU/smoke.sh --target local --record`; poi `bash $PU/run-tests.sh --static --expect-red` | «tutti i test falliscono» |
| L3 | Host sul PHP nuovo | `"php": "<PHP_TO>"` in `.dunebox/config.json` (MCP `set_host_php`); ini **web** `C:/devConfig/php/php-<PHP_TO>.ini`: `short_open_tag = On` se il sito usa `<?`, `display_errors = Off`; **riavvio servizi** | `env.sh` senza avvisi; `run-tests.sh --smoke` FALLISCE |
| L4 | Core e progetto | `php $PU/patch.php` (dry-run) poi `--apply` | checks C*/P* PASS, lint `from` ok, commit |
| L5 | Librerie | skill `mig-update-lib` per ogni riga di `libs.lock` | L* PASS, API dei chiamanti verificate, commit |
| L7 | Smoke | `run-tests.sh --smoke` (front); `smoke.sh --target local --admin-cookie 'NOME=VALORE'` (admin); prove manuali admin: nuovo/modifica/salva/ricerca; `compare-prod.sh --confirm-prod --shots` | 0 FAIL; ogni WARN valutato (`mig-fix-runtime-error`) |
| L8 | Verde | `run-tests.sh --static` | tutto PASS (anche A1, A2) |
| L9 | Report | skill `mig-report` | `_migration/REPORT.md` |

**Rollback LOCAL**: passo in corso `bash $PU/rollback.sh`; tutto `bash $PU/rollback.sh mig/base` + host sul PHP vecchio; DB `bash $PU/restore-db.sh <file> --confirm`.

## PROD
| # | Passo | Chi | Fatto quando |
|---|---|---|---|
| P0 | `ssh … "<php nuovo> -m" \| Out-File -Encoding ascii _migration/prod-phpXX-modules.txt` e `ssh … "<php nuovo> -i \| grep -E '^(short_open_tag\|display_errors) '" \| Out-File -Encoding ascii _migration/prod-phpXX-ini.txt`; controllare anche cPanel › MultiPHP INI Editor | utente | `env.sh` senza avvisi su PROD |
| P1-P2 | Backup PROD con `prod-to-local` (sito reale: occhio ai link `www` → `public_html`) e `backup-db.sh --verify <dump>` | agente, password dell'utente | copia + `.verified` |
| P3 | `bash $PU/deploy-pack.sh --prod-copy <dir> --prod-dump <dump>` (prima `--dry-run`) | agente | `out/deploy-*/` con `deploy-manifest.txt` |
| P3b | Manutenzione ON: `bash $PU/maintenance.sh on` (pagina `_migration/manutenzione.html`, blocco 503 dopo `RewriteEngine On`, escluso l'IP di questo PC) | agente, con permesso | da questo PC 200, da un'altra rete la pagina 503 |
| P4 | `bash $PU/deploy-push.sh --pack <out/deploy-…> --dry-run`, poi senza `--dry-run` (istantanea, applica, verifica SHA, rollback automatico) | agente, con permesso | «OK: deploy applicato» |
| P5 | cPanel › MultiPHP Manager → handler nuovo | utente | versione cambiata |
| P6 | `smoke.sh --target prod --confirm-prod`, `compare-prod.sh --confirm-prod --shots`, `error_log`; prove manuali: upload foto, PDF con login, invio form (SMTP reale), tutte le lingue | agente + utente | 0 FAIL |
| P7 | Manutenzione OFF: `bash $PU/maintenance.sh off` (toglie solo il suo blocco) | agente, con permesso | il sito risponde da un'altra rete |

**Rollback PROD**: `bash $PU/deploy-rollback.sh --pack <out/deploy-…>` (rimette l'istantanea) + l'utente rimette l'handler vecchio; smoke. Il DB non cambia. Senza SSH: `rollback.tar.gz` + `rollback-delete.txt` dal File Manager.
**Mai caricare**: `.htaccess` (si modifica solo a mano), `.user.ini`, `.dunebox/`, `_migration/`, `.claude/`, `.git/`, i `KEEP_UNTRACKED`.

Il blocco di manutenzione lo scrive `remote/htaccess-maint.sh` (solo righe tra marcatori `# >>> php-upgrade manutenzione` … `# <<< php-upgrade manutenzione <<<`). Se serve incollarlo a mano: `bash $PU/../remote/htaccess-maint.sh on <copia del .htaccess> /tmp/stato manutenzione.html <IP>` lo genera su una copia.
