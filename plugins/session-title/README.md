# session-title

Nomi di sessione con il prefisso dell'utente, pensato per il server di STAGING condiviso (una cartella di config per utente, es. `/srv/claude-config/danilo`). Si installa solo dove serve: non fa parte di `danilo-claude-skills`.

```
/plugin install session-title --marketplace Danilo-enesi/danilo-claude-skills
```

Per averlo solo per il proprio utente basta installarlo con scope `user` (finisce nel proprio `settings.json`).

## Cosa fa

- **Prefisso**: nome della cartella di config in maiuscolo (`/srv/claude-config/danilo` → `DANILO`; con `~/.claude` l'utente di sistema).
- **Al primo prompt** di una sessione ancora senza nome (`UserPromptSubmit`): `DANILO-<PROGETTO>-CLAUDE`, dove il progetto è la cartella subito dopo la **prima** cartella di iniziali (`ABC`, `YZ`, `0-9`): `/home/www/html/web/GHI/hpmotorrad/admin` → `DANILO-HPMOTORRAD-CLAUDE`. Fuori da quella struttura non fa nulla. Non si fa all'avvio perché dare un nome salva la sessione: `/resume` si riempirebbe di sessioni aperte e mai usate.
- **A mano**: `/user-title FIX-ESPANGO` → `DANILO-FIX-ESPANGO`. Il nome lo mette l'hook; il comando fa solo confermare il modello (un prompt bloccato farebbe perdere il nome).
- **Duplicati**: se un'altra sessione dello stesso progetto (sottocartelle comprese) ha già quel nome aggiunge `-2`, `-3`, …

Richiede `bash`.
