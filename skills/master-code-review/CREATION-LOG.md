# CREATION-LOG: skill `master-code-review` (ex `master-core-findings`)

> **Rinominata il 2026-09-09**: da `master-core-findings` a **`master-code-review`**.
> Motivo: il nome non comunicava che è una skill di *controllo qualità* del codice — era
> pensata così fin dall'inizio (vedi §1) ma "findings" suonava a ricerca/report, non a gate
> di qualità. Insieme al rename, **rework strutturale del §2 qui sotto**: la delega a
> `master-review` (plugin esterno) e parte del criterio comportamentale di
> `master-core-fields`/`master-page-content` sono stati **sostituiti da script deterministici**
> in `scripts/*.php`. Motivo del rework: gli utenti hanno osservato che gran parte del livello 1
> (strutturale) e buona parte del comportamentale (destinazione di un campo, antipattern noti)
> sono verifiche meccaniche — "esiste X?", "il Model estende Y?" — che uno script fa più
> veloce, più economico e più deterministico di un modello che rilegge il criterio ogni volta.
> **Il §2 originale qui sotto descrive il design SUPERATO** (delega a `master-review`): resta
> per la storia, non riscriverlo, ma non è più lo stato attuale — vedi `SKILL.md` §Regola
> mentale n.3 per il design corrente. Il livello 2 (Laravel) e 3 (DRY/generale) **non sono
> stati toccati** da questo rework: restano manuali, da rivedere in una sessione futura.
>
> **Riferimenti aggiornati in altre skill del repo**: `project-manager` (`reference/execution.md`,
> `reference/role-and-environments.md`, `reference/verification.md`, `reference/workers.md`) e
> `CLAUDE.md` citavano `master-core-findings` per nome — aggiornati a `master-code-review` nella
> stessa sessione. `subagent-empowerment` non la citava (verificato via grep) e non è stata
> toccata.

> **Rinominata il 2026-08-05**: da `master-core-alignment` a **`master-core-findings`**.
> Motivo: "alignment" nominava un'azione (allineare) che la skill non compie — è read-only e
> restituisce findings. Il nome ora dice il mestiere. **Nel resto di questo file il nome vecchio
> resta scritto dov'era**: è un log di sessioni passate, non lo si riscrive a posteriori.
> Nella stessa sessione la modalità `tester` è stata **staccata dal flusso automatico** PM →
> Orchestratore (non era ancora pronta): vedi la nota in `~/.claude/design/2026-07-29-tester-pipeline.md`.

## 0. Cos'è questo file (e cosa non è)

- **Non lo carica mai il modello**: `SKILL.md` non lo referenzia. Costa **zero contesto**.
- Non documenta *cosa fa* la skill (quello è `SKILL.md`). Documenta **perché è progettata
  così**, e quali scelte **non vanno "ripulite"** da chi la modificherà in futuro. È l'ADR
  di una skill di criterio.
- Scritto il **2026-07-29**, nella stessa sessione in cui la skill è stata corretta
  (§3). Ciò che precede quella sessione non è verificabile: `~/.claude` non è un repo git,
  non c'è storia né autore. Marcato **[DA CONFERMARE]** dove si tratta di inferenza.

## 1. Scopo dichiarato (dalle parole dell'utente, 2026-07-29 — non a memoria)

> «Questa skill ha il fine di **addestrare l'agente iniettando convenzioni, guide, regole e
> altri strumenti** per far sì che la sua generazione di codice sia fedele ai principi del
> framework. Siccome sono cose generali ci basiamo su master-core e altre convenzioni chiare
> tra vari progetti. Questa skill funziona principalmente per **l'admin**, perché il front
> varia molto da progetto a progetto.»

Tre conseguenze dirette di questa frase, da tenere presenti prima di modificare qualunque
regola qui dentro:

1. **Non è un linter generico**: il criterio è sempre "fedeltà al framework", non "codice
   pulito" in astratto. Per questo la gerarchia (§Regola mentale n.3 di `SKILL.md`) mette
   master-core al livello 1 e SOLID/DRY all'ultimo — anche quando una best practice generica
   suggerirebbe altro, vince master-core.
2. **Ambito = admin, non front.** Non è un dimenticanza né un "per ora": è **strutturale**. Il
   front (Blade/CSS/JS/markup) varia troppo da progetto a progetto per avere un criterio
   comune verificabile — non esiste un "front-core" condiviso come esiste master-core per
   l'admin. `SKILL.md` §Regola mentale n.2 lo dichiara come fuori ambito permanente, non come
   TODO. **Non estendere questa skill al front** senza prima aver capito se esiste davvero una
   convenzione condivisa da più progetti da codificare (al momento non c'è).
3. **"Convenzioni chiare tra vari progetti"** è il criterio di ammissione per ogni nuova regola
   di livello 1: se una convenzione vale solo per UN progetto, non appartiene a questa skill
   (appartiene a quel progetto, es. `CLAUDE.md` locale). Vedi §4 per il meccanismo con cui
   questo viene già rispettato.

## 2. Design: perché delega invece di ripetere

La skill **non contiene** le regole strutturali (UUID, PSR-4, struttura modulo…): le cita da
`master-review`. Questo non è pigrizia, è una scelta di manutenzione verificata sul disco:

| Fonte del criterio di livello 1 | Dove vive | Tipo |
|---|---|---|
| Convenzioni strutturali (UUID, classi base, PSR-4, migrazioni 3 file) | skill `master-review` | **plugin** `master-laravel-enesi-plugin` (`plugins/cache/enesi-master/.../skills/master-review`) |
| Campi form (`addField`, options provider) | skill `master-core-fields` | skill utente (`~/.claude/skills/master-core-fields`) |
| Blocchi di contenuto (`page_contents`) | skill `pages-content-blocks` | skill utente |
| "Esiste già un pacchetto?" | agent `master-package-scout` | **plugin** `master-laravel-enesi-plugin` |

**Il fatto non ovvio**: due delle quattro fonti (`master-review`, `master-package-scout`)
vivono in un **plugin versionato** (`1.0.0` al momento di scrivere), non in `~/.claude/skills`
come questa skill e i suoi satelliti diretti. Conseguenza pratica: se il plugin viene
aggiornato, i numeri di sezione citati nei findings (es. *"master-review §1 UUID"*) possono
**disallinearsi silenziosamente** — nessun meccanismo li tiene sincronizzati. Chi trova un
finding che cita una sezione inesistente in `master-review` deve sospettare questo, non un
errore del modello.

**Perché non ricopiare quelle regole qui dentro "per sicurezza"**: lo si è scartato
esplicitamente (vedi `SKILL.md` §1️⃣ — "questa skill non ricopia quelle regole"). Duplicare
significa avere due copie che possono divergere; l'unica fonte di verità per lo strutturale
resta `master-review`, aggiornabile in un solo posto (il plugin).

## 3. Correzioni della sessione 2026-07-29 (perché sono state fatte)

Tre problemi reali sono emersi **osservando l'uso effettivo** della skill, non per
ispezione teorica:

### 3.1 — Caricamento incondizionato dei satelliti (bug segnalato dall'utente)

**Sintomo osservato**: l'utente ha notato che `master-core-fields` veniva caricata **ogni
volta** che girava `master-core-alignment`, anche su file che non avevano nulla a che fare
con campi di form (Model, migration, Controller).

**Causa**: `SKILL.md` §1️⃣ e §Fonti di verità elencavano `master-core-fields` e
`pages-content-blocks` come "fonti da cui prendere le convenzioni", senza mai scrivere
esplicitamente *quando NON servono*. Un elenco di fonti letto senza condizione si legge
facilmente come "carica tutte queste ad ogni esecuzione".

**Correzione**: aggiunta la condizione esplicita in tre punti (§1️⃣, §Fonti di verità,
§Procedura passo 1): *"carica `master-core-fields` SOLO se il file è un `config.php` con
`addField(...)`"* e l'equivalente per `pages-content-blocks`. **Non rimuovere questa
condizione** ripulendo il testo come "ridondante" — è ridondante apposta, negli stessi tre
punti dove prima mancava, perché è lì che un lettore/agente distratto la cerca.

### 3.2 — Rimozione della dipendenza dal comando `/align-to-master`

Il comando `/align-to-master` (il "braccio" che scriveva `docs/` e applicava le correzioni)
è stato **eliminato** su richiesta esplicita dell'utente: *"non lo userò da solo"*. Prima di
questa sessione, `master-core-alignment` era scritta assumendo che esistesse sempre un
consumatore che scrive i findings su file — frasi come *"sarà il comando a scriverli"*.

**Correzione**: la skill ora dichiara esplicitamente che **restituisce sempre i findings
inline** a chi l'ha invocata (utente diretto, worker, Orchestratore/PM), e che sta a
quest'ultimo decidere se/come applicarli. Non presuppone più un comando specifico a valle.
Le due skill che la usano per delegare correzioni (`orchestrator`, `project-manager`) sono
state aggiornate per dire "delega un worker che carica `master-core-alignment` e corregge i
findings" invece di nominare il comando ormai inesistente.

**Se in futuro serve di nuovo un flusso "report + fix automatico su file"**: non ripristinare
il vecchio comando per abitudine — verificare prima se un worker delegato con
`subagent-empowerment` (ex `poteri-sottoagenti`) copre già il caso, che è lo scopo per cui è
stato rimosso.

### 3.3 — Nessuna invocazione registrata: la skill non risulta mai usata

`skill-usage.jsonl` non contiene alcuna voce per `master-core-alignment` alla data di
scrittura. La skill ha **3 consumatori dichiarati** (`orchestrator`, `orchestrator/reference/
workers.md`, `project-manager`) ma **zero esecuzioni osservate**. Tutte le correzioni di
questa sessione (§3.1, §3.2) sono quindi **non testate in condizioni reali** — sono corrette
per lettura attenta del testo, non verificate rieseguendo la skill su un file reale e
osservando quali altre skill vengono effettivamente caricate. Vedi §6 Test.

## 4. Difesa strutturale già presente — perché il vincolo "SOLO SEGNALA" non è un gate reale

Verificato sul frontmatter di `SKILL.md`: **non dichiara `allowed-tools` né
`disable-model-invocation`**. Il "non modifica mai codice, non scrive file" (§Regola mentale
n.1) è **un'istruzione testuale**, non un'restrizione imposta dall'harness — esattamente lo
stesso limite già documentato per `master-sitemap` (vedi il suo `CREATION-LOG.md` §2bis: le
skill non applicano `allowed-tools` come farebbe un comando).

> `master-sitemap` vive nel plugin Enesi, non fra le skill personali: i riferimenti al suo
> `CREATION-LOG.md` puntano a `~/Dev/master-laravel-claude-plugin/skills/master-sitemap/`.

**Conseguenza pratica**: se un agente che ha caricato questa skill ha comunque accesso a
`Edit`/`Write` (perché il suo profilo/worker glieli concede per altri motivi), **nulla nel
meccanismo la ferma** dal correggere il codice invece di limitarsi a segnalare. La disciplina
regge solo finché il testo della skill viene seguito alla lettera. Chi delega worker con
questa skill (`orchestrator`, `project-manager`) dovrebbe, quando possibile, dare al worker
di rilevamento **solo tool read-only** (vedi §1 mappa modelli in `subagent-empowerment`, o
l'agent `read-only`) invece di fidarsi solo del testo della skill.

## 5. Difese deliberate — non rimuoverle credendo di fare pulizia

1. **"Non inventare convenzioni: cita sempre la fonte"** (§Regole finali) — impedisce che un
   finding affermi una regola master-core mai verificata. Legato a **"da verificare" invece
   di affermare** quando la fonte non è chiara: è l'unica difesa contro falsi positivi
   autorevoli (un finding sbagliato ma scritto con sicurezza è peggio di nessun finding).
2. **Attribuzione al livello più alto** (§Regola di attribuzione): se lo stesso problema è
   coperto da più livelli, va sempre citato quello più alto. Senza questa regola, un problema
   di master-core rischia di essere segnalato come "generico/DRY" — gravità sottostimata.
3. **Il gating dei satelliti aggiunto in §3.1**: tre ripetizioni della stessa condizione
   (§1️⃣, §Fonti di verità, §Procedura) sono intenzionali, non un difetto di editing — è lo
   stesso pattern di ridondanza voluta usato in `master-sitemap` per gli avvisi critici.
4. **"Non segnalare `vendor/`"** (§Regole finali) — impedisce di trattare codice di terze parti
   read-only come se fosse refactorabile nel repo applicativo.

## 6. Test: NESSUNO ESEGUITO — debito noto e dichiarato

Come per `master-sitemap`, questa skill è stata **scritta e corretta ma mai osservata in
esecuzione reale** (§3.3). Da eseguire, idealmente con `--agent read-only` per restare in
sicurezza:

| # | Scenario | Esito atteso | Fallimento = |
|---|---|---|---|
| T1 | Eseguire su un `Model.php` senza campi form né blocchi contenuto | **Nessuna** invocazione di `master-core-fields`/`pages-content-blocks` | Le carica comunque → §3.1 non è bastato, il gating va reso più esplicito o spostato in cima al file |
| T2 | Eseguire su un `config.php` con `addField('Select', ...)` | Carica `master-core-fields`, cita §Select nel finding | Non la carica, o inventa la regola senza consultarla |
| T3 | Eseguire su una view Blade con solo markup/CSS/JS | Dichiara il file fuori ambito e si ferma | Prova comunque a segnalare qualcosa → §Regola mentale n.2 ignorata |
| T4 | Invocarla da sola (senza Orchestratore/PM/comando) su un file con un problema noto | Restituisce i findings **inline nella risposta**, non tenta di scriverli su `docs/` | Cerca un comando/file di output inesistente → residuo della dipendenza rimossa in §3.2 |
| T5 | Finding che cita `master-review §N` | La sezione `§N` esiste davvero nella versione corrente del plugin | Sezione inesistente/disallineata → conferma il rischio di §2 (plugin versionato separatamente) |

T1 è il più importante: è il test diretto del bug che ha motivato questa sessione di
correzioni.

## 7. Punti aperti [DA CONFERMARE]

1. Chi ha scritto le regole originali e quando — nessuna evidenza recuperabile (niente git,
   niente `skill-usage.jsonl` precedente a questa sessione).
2. Se/quando arriverà una richiesta di estendere questa skill al **front**, va presa come
   segnale per **creare una skill nuova e separata** (non una sezione qui dentro) — coerente
   col motivo per cui oggi il front è escluso (§1.2). Non forzare il front dentro
   `master-core-alignment` "tanto è la stessa idea".
3. Se in futuro emergono convenzioni di progetto comuni a più repo ma non ancora coperte da
   nessuna delle quattro fonti di §2 (es. permessi/ruoli, scoping multi-sito, notifiche), vanno
   aggiunte come **nuovo bullet in §1️⃣ di `SKILL.md`**, con la stessa domanda di ammissione
   di §1.3 qui sopra ("vale per più progetti?"). Se la lista cresce oltre 5-6 voci, vale la
   pena valutare satelliti dedicati per ciascuna (stesso pattern già usato per
   `master-core-fields`/`references/`), ma non prima — oggi sono solo 3 righe corte.
