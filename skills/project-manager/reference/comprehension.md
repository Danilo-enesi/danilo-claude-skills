# Fase 0 — Comprensione del problema

Riferimento della skill `project-manager`. Leggilo quando apri la Fase 0.
Questa è la fase più importante: è vietato procedere oltre finché non esiste
una comprensione completa, senza ambiguità critiche.

## Domande obbligatorie iniziali

Prima di qualsiasi altra analisi, sempre, indipendentemente da quanto sembrino
già deducibili dal messaggio dell'utente:

1. **Ambiente e versione** — tre opzioni:
   - **master-core** (il CMS Laravel attuale) — quale versione?
   - **master-legacy** — il **vecchio CMS, non-Laravel** (PHP4/5 "Master v7.x",
     modello dati EAV). Chiarisci sempre questa distinzione all'utente: non è
     "una versione vecchia di master-core", è un sistema diverso — vedi
     `role-and-environments.md`.
   - **generico** — un progetto/stack **fuori dall'ecosistema master-\***
     (altro framework, altro linguaggio, o un Laravel qualsiasi senza il
     core Enesi). In questo caso non valgono le sezioni master-core/
     master-legacy di `role-and-environments.md`, `workers.md` e
     `verification.md`: le convenzioni del progetto (framework, comandi di
     build/test/lint) vanno accertate qui, negli step della pipeline sotto,
     non assunte.

   Se il problema coinvolge più di uno di questi (raro, ma possibile in una
   migrazione), fallo dichiarare esplicitamente.
2. **Documentazione finale** — sì/no, se al termine del progetto va prodotto
   un pacchetto di consegna (lo farà il Documentarian, `/documentarian`, in
   fase di chiusura — vedi `validation.md`).

Non proseguire finché non hai risposta a entrambe. Non sono soggette alla
classificazione critiche/non critiche dello Step 7 sotto: sono sempre
obbligatorie.

## Prima di partire: c'è già un `docs/asked/` per questo lavoro?

Controllalo *prima* di aprire la Fase 0. Se esiste un file che copre questa
richiesta, la comprensione è già stata fatta e confermata — riparti da lì
(verificando con l'utente che sia ancora valido) invece di ripetere tutto.
Il campo `Fase:` in testa al file ti dice anche dove si era arrivati
(§handoff.md — sezione "Stato" più sotto).

## Pipeline di comprensione (12 step)

1. Estrai tutti i requisiti espliciti.
2. Individua i requisiti impliciti.
3. Analizza il contesto, applicando l'ambiente già determinato (in master-core
   appoggiati alla documentazione della versione indicata; in master-legacy
   tieni presente l'incertezza strutturale).
4. Identifica le informazioni mancanti. In master-legacy, l'assenza di
   documentazione non è di per sé un'informazione mancante da colmare subito:
   è una condizione attesa. Le domande all'utente restano lo strumento
   primario; l'esplorazione è lavoro operativo, delegato più avanti.
5. Ricerca contraddizioni.
6. Analizza gli edge case.
7. Classifica le informazioni mancanti: critiche / non critiche.
8. Formula un unico gruppo di domande organizzato per argomento.
9. Ricevi le risposte.
10. Ripeti l'analisi — termina solo quando non restano ambiguità critiche.
11. **Compila la plantilla** `templates/comprehension.md`. Non produrre un
    riepilogo libero: il template è l'unico deliverable di questo step.
    Include la tabella dei presupposti fattuali validati (vedi sotto) e i
    Criteri di accettazione — questi ultimi alimentano il campo `Verify`
    delle voci di `templates/task.md` più avanti.
12. Chiedi conferma esplicita all'utente. Solo dopo puoi procedere.

Durante la comprensione **non è consentito**: proporre soluzioni, pianificare
attività, pensare all'implementazione. L'unico obiettivo è comprendere.

## Validazione dei presupposti fattuali — sempre delegata, in sola lettura

Un'affermazione fattuale sul codice ("il modulo X esiste", "il campo Y è
gestito dal modulo Z", "esiste già un pacchetto per W") **non è un fatto**
finché non è verificata — che venga dall'utente o da una tua deduzione.
Costruire obiettivo e strategia su un'assunzione errata è la causa più
frequente di piani inutili.

Prima dello Step 11, valida ogni presupposto rilevante delegando a un
sottoagente **read-only** (mai a uno che scrive):

- esistenza/posizione di file, moduli, campi, chi-usa-cosa → `Explore`;
- "esiste già un pacchetto ufficiale per X?" → `master-laravel-enesi-plugin:master-package-scout`;
- mappatura/scoperta su dati o strutture legacy → `master-laravel-enesi-plugin:master-migration-analyst`;
- analisi più ampia e multi-step → `general-purpose`.

Formula la delega come **domanda di verifica secca**, non come incarico a
progettare o modificare. Questi worker sono per definizione **L1** (`haiku`,
nessun MCP se non serve, nessuna scrittura) — applica `subagent-empowerment`.

Ogni presupposto diventa confermato o smentito, e va registrato nella tabella
del template. Una smentita modifica comprensione/obiettivo/strategia e va
comunicata all'utente esplicitamente ("avevi assunto che…, ma la verifica
mostra che…").

In master-legacy questa è solo la validazione minima per rendere sensata la
comprensione: la scoperta vera resta la prima macro-fase della strategia,
eseguita in fase operativa (`execution.md`).

## Dopo la conferma (Step 12)

Scrivi **§1 Comprensione** di `docs/asked/<data>-<slug>.md` (il template
compilato) e imposta `**Fase:** comprensione`. Poi passa a definire obiettivo
e strategia — vedi `execution.md`.
