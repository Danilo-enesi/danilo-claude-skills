# Ambienti di lavoro: master-core vs master-legacy (operativo)

Riferimento della skill `project-manager`. Da leggere **solo** se il lavoro
tocca master-legacy, o se non sai in quale dei due ambienti stai (§3 di
`execution.md`). Per la parte concettuale/di comprensione vedi
`role-and-environments.md`.

## Come capire in quale ambiente sei

- **master-core** — progetto Laravel con `enesisrl/laravel-master-core` in
  `private/composer.json`, moduli in `private/master/Modules/<Nome>/`.
  Variante: progetti **from-scratch** senza il pacchetto Composer ma con la
  stessa struttura scritta a mano (il namespace `Master\` e
  `master/Modules/` esistono comunque).
- **master-legacy** — vecchio CMS PHP "Master v7.x", nessun Laravel, nessun
  `artisan`, modello dati **EAV** su MySQL.

Se un lavoro tocca entrambi (tipicamente una migrazione), trattalo come
legacy per la disciplina di scoperta: è il lato che detta i rischi.

## master-core

- Ambiente **ben documentato e a versioni**. Prima di far esplorare un
  worker a tentativi, fagli consultare la documentazione della **versione
  specifica** del progetto — le versioni del core divergono in modo
  sostanziale tra progetti.
- Prima di creare un modulo/funzionalità custom, **verifica sempre se esiste
  già un pacchetto ufficiale** che la copre. Delega la verifica a
  `master-laravel-enesi-plugin:master-package-scout` — non decidere a
  intuito.
- **Incertezza attesa: bassa.** Se un worker qui riporta molta incertezza, è
  un segnale da investigare, non da accettare: di solito significa che ha
  cercato nel posto sbagliato (es. nel Facade invece che in
  `Classes/Module.php`).

## master-legacy

- Ambiente **scarsamente o per nulla documentato**.
- **La primissima attività che deleghi è sempre di scoperta/esplorazione
  mirata** — proporzionata al problema, mai una mappatura generale
  preventiva.
- Tratta l'esito della scoperta come **soggetto a revisione**: se cambia la
  comprensione, aggiorna il piano di attività e comunicalo all'utente. Non
  tirare avanti un piano costruito su una comprensione superata.
- **Ogni scoperta rilevante va documentata dal worker che l'ha fatta** (mai
  scritta da te in prima persona), per conservarla per problemi futuri nello
  stesso ambiente.
- L'incertezza qui è **strutturale**: dichiarala sempre esplicitamente. Non
  colmarla facendo tu l'esplorazione — delega.

## Perché la scoperta va delegata e non fatta da te

Non è una regola di stile. Esplorare legacy consuma molto contesto in
letture che poi non servono più: se la fai tu, il contesto che ti serve per
orchestrare (stato delle attività, decisioni, verifiche) viene mangiato da
dump di file EAV. Un worker la fa, restituisce la conclusione, e il suo
contesto muore con lui.
