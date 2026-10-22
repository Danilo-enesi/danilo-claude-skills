# prod-to-local

Porta un sito (file + dump del DB) dal server di produzione a questo PC via SSH, come un unico job "tutto o niente".
Non crea host, non importa il DB e non tocca la config del sito: quello resta a te.

## Skill

| Skill | Cosa fa |
|---|---|
| `prod-to-local-workflow` | punto d'ingresso: ordine dei passi e regole comuni |
| `prod-vault` | salva/elenca/rimuove le password (finestra di Windows, cifrate con DPAPI) |
| `prod-preflight` | controllo in sola lettura: host key, login, tool, spazio libero, dimensione del sito |
| `prod-pull-code` | file del sito -> nuova cartella locale (default `C:\devProjects\<job>`) |
| `prod-pull-db` | `mysqldump` senza lock (tabelle, viste, funzioni, procedure, trigger) -> nuovo `.sql.gz` locale, con controllo FK disattivato e senza `DEFINER` |
| `prod-rollback` | annulla tutto ciò che il job ha creato, oppure lo conferma (`--forget`) |

## Garanzie

- **Sul server** si eseguono solo gli script in `remote/`, con `nice`, da utente normale: niente `sudo`, niente installazioni. L'unica scrittura è un file temporaneo `$HOME/.prod-to-local-*`, cancellato subito dopo il download (e in ogni caso dal rollback).
- **Transazioni**: ogni risorsa creata viene annotata in `~/.prod-to-local/jobs/<job>.ledger` *prima* di crearla. Se un passo fallisce, lo script annulla l'intero job. Le cartelle esistenti non vengono mai sovrascritte, e viene cancellata solo la cartella con il marker `.prod-to-local.job` del job.
- **Credenziali**: `scripts/vault.ps1` (DPAPI, utente corrente). Le password arrivano a `ssh` tramite `askpass.sh` e al `mysqldump` remoto tramite stdin (`MYSQL_PWD`), mai sulla riga di comando. L'hook `guard-vault.sh` impedisce a Claude di leggere il vault e chiede sempre il permesso per ogni script che lo usa.
- **Integrità**: SHA-256 confrontato fra server e PC; il dump deve finire con `-- Dump completed`; numero di routine e viste uguale a quello del server.
- **Dump importabile in locale** (`scripts/clean-dump.sh`): `SET FOREIGN_KEY_CHECKS=0/1` intorno a tutto il dump e rimozione dei `DEFINER=utente@host`. I valori scritti dentro il corpo di viste/funzioni (es. `'localhost'`, `` `db_prod`.tabella ``) non vengono riscritti: escono come `REVIEW:` e decide l'utente.

## Test

```
bash plugins/prod-to-local/tests/selftest.sh
```

Gira offline, con `ssh`/`scp`/`mysqldump` finti che eseguono gli script remoti in una cartella temporanea.
