# Validazione del risultato e chiusura

Riferimento della skill `project-manager`. Leggilo dopo che `verification.md`
ha prodotto l'acta in `docs/tested/<slug>.md` (o dopo `execution.md` passo 8
se la verifica è stata esplicitamente saltata).

## Validare non è "tutte le task fatte"

Il compito qui non è verificare che tutte le attività siano terminate: è
verificare che **il problema iniziale sia stato realmente risolto**.
Confronta problema iniziale, obiettivo definito e risultato finale. Non
ricostruire il risultato a memoria: le fonti concrete sono la checklist §2
di `docs/asked/<slug>.md` (con le 4 categorie annotate da `execution.md`
passo 6) e l'acta di `docs/tested/<slug>.md`.

L'acta di verifica dice se il codice **funziona e regge**; la checklist dice
se i worker hanno fatto **ciò che dicevano**. Nessuna delle due, da sola, è
"il problema è risolto" — quella conclusione la tiri tu, qui.

- Se l'acta ha verdetto `⛔ non passa`, o ha voci sotto "Richiede validazione
  dell'utente" che toccano criteri di accettazione: **il progetto non è
  chiuso**. Presenta all'utente cosa manca ed eventualmente una nuova
  strategia/correzione — non chiudere per pigrizia.
- Se il verdetto è `⚠️ passa con riserve`: dichiara le riserve esplicitamente
  all'utente prima di proporre la chiusura, non lasciarle sepolte nell'acta.
- Se emergono 3 giri falliti di correggi→ri-verifica (limite di
  `verification.md`), è un problema strutturale: presentalo come tale
  all'utente, non come un ultimo giro in più.

Aggiorna `**Fase:** validata` una volta completata questa valutazione (a
prescindere dall'esito — anche "non risolto, serve un nuovo giro" è uno
stato valido da registrare).

## Chiusura del progetto

Quando il problema risulta davvero risolto:

- approva la chiusura;
- se l'utente ha richiesto documentazione finale (§Domanda 2 di
  `comprehension.md`), attiva il **Documentarian** (`/documentarian`) per il
  pacchetto di consegna — autorizza esplicitamente l'analisi profonda se il
  lavoro è ampio o critico; il Documentarian legge sia `docs/asked/` sia
  `docs/tested/` come fonti;
- presenta all'utente il riepilogo conclusivo;
- imposta `**Fase:** chiusa`.

Se la documentazione non è stata richiesta, salta il passaggio del
Documentarian e chiudi con il solo riepilogo.
