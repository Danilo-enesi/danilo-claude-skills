# Strategia ed esecuzione

Riferimento della skill `project-manager`. Leggilo quando la Comprensione
(Step 12) è stata confermata dall'utente. Copre: come definire la strategia,
come scomporla in attività, come delegare e verificarne la veridicità, e come
si chiude la fase esecutiva (verifica automatica + validazione).

Non c'è handoff a un'altra entità: sei sempre lo stesso loop. Questo file
descrive semplicemente **la fase successiva** del flusso, non un cambio di
persona da annunciare all'utente con una cerimonia a parte.

## 1. Definire la strategia

La strategia descrive **come**, non il dettaglio implementativo. Non contiene
attività, non contiene codice. Definisce solo: aree coinvolte, macro-fasi,
dipendenze principali, rischi, ordine logico.

- Se il lavoro tocca **master-legacy**, la prima macro-fase è sempre una
  scoperta mirata e proporzionata (mai una mappatura generale) — presentala
  come soggetta a revisione: ciò che emerge può cambiare le fasi successive,
  e questo va detto all'utente in anticipo.
- Se l'utente ha richiesto documentazione finale, includila come ultima
  macro-fase.
- **Allineamento fin dalla progettazione**: il criterio dipende
  dall'ambiente dichiarato in Fase 0.
  - **master-core/master-legacy**: applica `master-code-review` (1°
    master-core → 2° best practice Laravel → 3° DRY/generali) come vincolo
    di qualità della strategia — non proporre un approccio che sai già non
    idiomatico (query in `config.php`, aggirare un pacchetto ufficiale, PK
    non-UUID).
  - **generico**: usa le convenzioni del progetto accertate in Comprensione
    (`templates/comprehension.md` — "Convenzioni del progetto") → best
    practice del suo framework → DRY/generali. `master-code-review` non
    si applica.
  Se un dettaglio tecnico va confermato, è materia della validazione dei
  presupposti in Fase 0, non da decidere a intuito qui.

Presenta la strategia come **testo normale conversazionale** — mai tramite
una modalità di pianificazione nativa che esegue automaticamente
all'accettazione. La conferma dell'utente autorizza a passare
all'esecuzione, non equivale ad averla già eseguita.

## 2. Comporre il brief (= appendere §2 a `docs/asked/`)

Il brief **non è un secondo documento**: il file `docs/asked/<slug>.md` *è*
il brief. Appendi solo **§2 Piano**, come checklist di macro-fasi (usa
`templates/task.md` per i campi Acceptance/Verify/File quando aggiungono
informazione reale). Tutto il resto è già in §1, scritto alla conferma della
Comprensione — non ricopiarlo: se un campo di §1 non è più esatto,
**correggilo lì**, non duplicarlo.

Aggiorna `**Fase:** strategia-confermata`.

## 3. Scomponi in attività

Traduci la strategia in attività concrete, eseguibili da un singolo worker.
Usa `TaskCreate`/`TaskUpdate`/`TaskList`/`TaskGet` come vista d'insieme dello
stato — non è opzionale. Individua dipendenze: cosa va in parallelo, cosa in
sequenza. Se il lavoro tocca master-legacy, leggi **`ambienti-legacy.md`**:
la prima attività è sempre di scoperta.

## 4. Scegli il worker giusto e potenzialo

Leggi **`workers.md`** (quale worker per quale attività, potenziamento via
`subagent-empowerment`, iniezione obbligatoria di `master-code-review` per
chi scrive PHP/Laravel, gestione dei conflitti in parallelo) e applicalo
prima della prima delega.

## 5. Delega con contesto sufficiente

Il prompt dice sempre: qual è il problema e perché, cosa è già stato
scoperto/deciso, cosa deve restituire e in che formato, se il worker deve
solo cercare o anche scrivere/modificare. Se serve documentazione (scoperta
legacy o finale), specificalo.

Lancia **più worker in parallelo** quando le attività sono indipendenti
(più chiamate `Agent` in un unico messaggio); usa `Workflow` per fan-out
ampi/ripetitivi solo se l'utente lo ha chiesto o il compito lo giustifica
chiaramente.

## 6. Ricevi e verifica la VERIDICITÀ

Un worker descrive quello che *intendeva* fare, non necessariamente quello
che ha fatto. Prima di segnare un'attività completata, apri con
`Read`/`Grep`/`Glob` i file toccati o l'output e classifica in **4
categorie** (riportale tutte, anche vuote — "nessuna" è informazione):

- **(a) allucinazione/incompletezza** — dice di aver fatto X ma il file non
  lo riflette, o è rimasto a metà;
- **(b) bug** — segnalati dal worker o notati nel diff;
- **(c) discrepanze col piano** — cosa era chiesto vs cosa è stato fatto;
- **(d) decisioni deliberate** — scelte prese dal worker su punti ambigui,
  non previste dal piano.

Questa è verifica di **veridicità, non di qualità**: la domanda è "quello
che dice di aver fatto, l'ha fatto?", non "funziona bene?" — quella è la
fase successiva (`verification.md`). Se trovi problemi, **non correggere
tu**: rispedisci al worker o delega una correzione mirata. Non rifare mai da
capo il lavoro di un worker "per sicurezza".

## 7. Spunta la checklist — solo se c'è

Se `docs/asked/<slug>.md` §2 ha una checklist (`- [ ]`), aggiornala man mano
(⏳ → 🔄 → ✅, o ⛔ se bloccata) e annota **sotto la voce** solo ciò che è
emerso dalle 4 categorie del passo 6 — una riga, non un report. Non
aspettare la fine: i `TaskList` non sopravvivono a una sessione nuova, quella
checklist è l'unico modo per riprendere dopo una chiusura.

Se il piano **non** ha una checklist (es. arriva da un `.md` scritto da
altri), non toccare il file: nessuna riga, nessuna ristrutturazione.

## 8. Chiudi la fase esecutiva → verifica automatica → validazione

Quando l'esecuzione è conclusa:

1. **Aggiorna `Fase:` a `eseguita`.**
2. **Passa alla verifica** leggendo **`verification.md`** e applicandola sul
   perimetro appena eseguito — è un passo automatico di questo stesso
   flusso, non un'invocazione separata che richiede conferma. L'unica
   eccezione: lavoro puramente documentale/non-codice, o l'utente ha
   esplicitamente rinunciato alla verifica per questo giro (dichiaralo).
   Aggiorna `Fase:` a `verificata` al termine.
3. **Passa alla Validazione del risultato** — vedi `validation.md`. Le tue
   fonti sono la checklist §2 (passo 7) e l'acta di verifica appena prodotta
   (`docs/tested/<slug>.md`), non la memoria.

## Cosa NON fare in questa fase

- scrivere/modificare codice applicativo tu stesso, anche se sembra più
  veloce che delegare;
- eseguire migrazioni, comandi distruttivi o modifiche dirette allo stato
  del progetto in prima persona;
- accettare il risultato di un worker come completato senza la verifica di
  veridicità (passo 6);
- rifare da capo il lavoro di un worker invece di correggerlo con una
  delega mirata;
- saltare la scoperta quando il lavoro coinvolge master-legacy;
- far passare la verifica di veridicità per una verifica di qualità: se il
  codice non è stato provato ancora, dillo — non lasciar credere che
  "✅ fatto" significhi "funziona" (a questo pensa `verification.md`);
- dichiarare un'attività completata senza aver riportato le 4 categorie;
- avviare un `Workflow` di propria iniziativa su compiti piccoli o non
  richiesti;
- iniziare l'implementazione subito dopo la conferma della strategia,
  saltando la composizione del brief (passo 2);
- esplorare autonomamente master-legacy "solo per capire" invece di
  delegare la scoperta.

## Chiarimenti durante l'esecuzione

Se emerge un'ambiguità che tocca vincoli, priorità o criteri di
accettazione, non decidere da solo: chiedi all'utente (`AskUserQuestion`).
Le questioni puramente tattiche (come suddividere, quale worker, ordine) le
decidi tu e le comunichi.
