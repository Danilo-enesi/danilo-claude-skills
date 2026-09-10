---
name: master-code-review
description: Controllo qualità del codice PHP/Laravel del Master Laravel Enesi — esegue script deterministici per le convenzioni strutturali e comportamentali (Fase 1), poi valuta ciò che gli script non possono coprire (best practice Laravel, DRY/SOLID, riuso di campi/blocchi esistenti). Produce l'elenco delle discrepanze (`file:line`, gravità, come correggerle), in ordine di priorità: (1) convenzioni master-core, (2) best practice Laravel, (3) DRY/SOLID. Attivala quando pensi «questo codice è fatto come si deve?», «controlla che segua le convenzioni», «un agente ha messo la query/logica nel posto sbagliato», «cosa andrebbe rifattorizzato?», «questo file è idiomatico per il progetto?». SOLO SEGNALA (sola lettura, solo PHP/Laravel): non scrive né modifica — restituisce i findings a chi l'ha invocata (utente, worker, Orchestratore), che decide se e come applicarli.
---

# Skill: Code Review — Master Laravel Enesi (criterio + script deterministici)

Questa skill è il **criterio** di qualità del codice per il Master Laravel Enesi. Restituisce solo i **findings**; chi l'ha invocata decide se applicarli, chiederne conferma, o passarli a un worker dedicato.

> **Rinominata il 2026-09-09** da `master-core-findings`. Motivo: il nome non comunicava che questa è la skill di **controllo qualità** del codice — vedi `CREATION-LOG.md` per la storia completa (incluso il nome precedente `master-core-alignment`).

## Regola mentale n.1 — questa skill SOLO SEGNALA

- **Sola lettura.** Esegue script (`scripts/*.php`, sola lettura — nessuno scrive file) e usa `Read`/`Grep`/`Glob`. **Non modifica mai codice, non scrive file, non crea `docs/`.**
- Il tuo output è un **elenco di reperti (findings)** nel formato §Formato del finding: ognuno ancorato a un `file:line` reale.
- Restituisci sempre i findings **inline nella risposta** a chi ti ha attivata (utente, worker, Orchestratore/PM). Non sei tu a scriverli su file o a correggerli: quello, se richiesto, è compito di chi ti ha invocata.

## Regola mentale n.2 — ambito: solo PHP / Laravel (per ora)

Valuti **solo codice PHP/Laravel**: Model, Controller, `config.php` di moduli, migration, Service Provider, Facade, Classi Module, Blade **limitatamente alla logica PHP** che contengono. **Fuori ambito** (non segnalare): CSS, JS, markup HTML/Blade puro, asset. Se un file è fuori ambito, dichiaralo e passa oltre.

---

## Regola mentale n.3 — Fase 1 è eseguita da SCRIPT, non a memoria

**Il cambio più importante di questa skill**: le convenzioni verificabili meccanicamente (esiste una colonna? il Model estende la classe giusta? il namespace corrisponde al percorso?) **non le valuti tu leggendo il codice a occhio** — le verifica uno script dedicato, deterministico, veloce ed economico. Il tuo lavoro è **eseguirlo, leggerne l'output JSON, e tradurlo in finding**; non ri-derivare a mano ciò che lo script ha già stabilito.

### Script disponibili (`scripts/`)

Ognuno è indipendente, sola lettura, richiamabile da CLI: `php scripts/<nome>.php <path>`. Restituisce JSON su stdout con `findings: [{rule, severity, file, line, message, confidence?}]`.

| Script | Cosa verifica | Dominio |
|---|---|---|
| `check-migrations.php` | UUID PK, soft deletes, audit fields `string(36)`+FK, split main/translations/values | Strutturale |
| `check-models.php` | Estende `Base\Models\Model`, `$keyType='string'`, `$incrementing=false` | Strutturale |
| `check-namespaces.php` | Namespace PSR-4 vs percorso fisico, naming PascalCase dei file | Strutturale |
| `check-base-classes.php` | `AdminController`/`Classes\Module` estendono `Crud\*`, non `Base\*` | Strutturale |
| `check-module-structure.php` | I 5 componenti di un modulo sono presenti | Strutturale |
| `check-package-provider.php` | `composer.json` dichiara `extra.laravel.providers`, config pubblicabile | Strutturale |
| `check-vendor-untouched.php` | Nessun file modificato sotto `vendor/enesisrl/` (richiede `--files=` o `--git-diff=<repo>`) | Strutturale |
| `check-field-destinations.php` | Il `name` di ogni `addField` ha una destinazione reale (`$fillable`, `$related`, media collection, `HasAddresses`) | Comportamentale (fields) |
| `check-field-antipatterns.php` | Query grezza dentro `config.php`, suffisso lang manuale, `Checkbox`/`Published` con `required`, campo mai in un tab, JS/CSS inline in Field custom | Comportamentale (fields) |
| `check-content-blocks.php` | Sistema `Contents` installato correttamente, rendering DB-driven (non hardcoded), media non cercati dentro `data` JSON | Comportamentale (blocks) |

**Limite dichiarato**: sono euristiche a regex/pattern-matching su file singoli, non un parser PHP/AST completo. Sono deterministiche e ripetibili, ma su casi ambigui emettono `confidence: "da_verificare"` invece di affermare un errore — rispetta quel flag, non promuoverlo a certo.

### Come si inseriscono nella procedura

1. **Identifica lo scope** (un modulo, un file, un intero progetto).
2. **Esegui gli script pertinenti allo scope** (es. su un `config.php` con `addField`: `check-field-destinations.php` + `check-field-antipatterns.php`; su una migration: `check-migrations.php`; su un intero modulo: tutti quelli strutturali + quelli comportamentali se applicabili).
3. **Traduci ogni riga di `findings` in un finding** nel formato §Formato del finding, citando `rule` dello script come fonte (es. "script check-models §model-key-type").
4. **Solo dopo** aggiungi ciò che gli script NON coprono (§Cosa resta a te qui sotto).

### Cosa resta a te (gli script non lo coprono)

- **Riuso**: esiste già un campo/tipo/blocco simile che si dovrebbe riusare invece di crearne uno nuovo? Richiede confronto semantico col catalogo, non solo esistenza — fonte: skill `master-core-fields` (§7, campi) / `master-page-content` (blocchi). *Carica quella skill satellite SOLO se il file in esame ha effettivamente `addField(...)` o tocca `page_contents`.*
- **Hardcode dubbio nei blocchi**: lo script segnala se manca del tutto la chiamata a `getBlockData()`/`getContentMedia()`, ma se è mescolata con testo hardcodato serve leggere il file — fonte: skill `master-page-content`.
- **"Esiste già un pacchetto ufficiale?"**: fonte: agent `master-package-scout`.
- **Livello 2 (Laravel)** e **Livello 3 (generale/DRY)**: interamente a tuo giudizio, vedi sotto — non ancora coperti da script (fase futura, non in questa revisione).

---

## Regola mentale n.4 — la gerarchia dei criteri (l'ordine è vincolante)

Una discrepanza si giudica sempre **in quest'ordine**. Il livello più alto vince: se master-core prescrive un pattern, quello prevale anche se una "best practice Laravel generica" suggerirebbe altro.

### 1️⃣ master-core / Master Laravel Enesi (priorità massima)
Le convenzioni dell'ecosistema `enesisrl/laravel-master-*` e del progetto. La parte **strutturale e comportamentale meccanica** è verificata dagli script (§Regola mentale n.3); la parte **di riuso/giudizio** resta a te (vedi sopra).

### 2️⃣ Best practice Laravel (quando master-core non prescrive nulla)
Idiomi Laravel standard: Eloquent al posto di query grezze quando appropriato, form request/validazione al posto di controlli sparsi, mass assignment governato da `$fillable`, niente logica pesante nelle route, uso corretto di relazioni/eager loading (evitare N+1), config/`.env` al posto di valori hardcodati, naming e struttura Laravel. *(Non ancora coperto da script — valutazione manuale.)*

### 3️⃣ Best practice generali (l'ultimo livello)
DRY, SOLID, separazione delle responsabilità, funzioni troppo lunghe/annidate, duplicazione, dead code, naming poco chiaro, magic number/stringhe. Interviene **solo** se i due livelli sopra non dicono già qualcosa di più specifico. *(Non ancora coperto da script — valutazione manuale.)*

**Regola di attribuzione:** ogni finding dichiara **a quale livello (1/2/3)** appartiene. Se lo stesso problema è coperto da più livelli, attribuiscilo al **più alto** e cita quello.

---

## Il caso tipico che devi saper riconoscere — "logica nel posto sbagliato"

È l'esempio che motiva questa skill (un agente crea un campo `Select` in un modulo, ma la **query** per le opzioni la scrive dentro il `config.php`, o costruisce a mano un array di risultati lì dentro). Rilevato automaticamente da `check-field-antipatterns.php` (rule `field-inline-query`); se lo script non lo copre in un caso specifico, i pattern da segnalare a mano sono:

- Logica di business dentro la definizione del form, dentro una view, o dentro una route.
- Accesso al DB dal Controller quando dovrebbe passare dal Model/Repository/Facade del modulo.
- Recupero dati duplicato in più punti invece di un unico metodo riusabile.

---

## Fonti di verità (dove leggere il criterio, non a memoria)

- **Convenzioni generali del progetto:** `CLAUDE.md` (UUID, audit fields, translations/values, struttura moduli, blocchi).
- **Strutturale e comportamentale meccanico:** gli script in `scripts/` (§Regola mentale n.3) — sono la fonte, non serve consultare altro.
- **Riuso di campi/tipi:** skill `master-core-fields`. *Carica solo se il file in esame ha `addField(...)`.*
- **Riuso/hardcode di blocchi:** skill `master-page-content`. *Carica solo se il file tocca `page_contents`/blocchi di contenuto.*
- **"Esiste già un pacchetto?":** agent `master-laravel-enesi-plugin:master-package-scout`.
- **Codice reale come modello di riferimento:** moduli in `private/master/Modules/*/` e i package in `private/vendor/enesisrl/laravel-master-*/` (in sola lettura).

Preferisci **sempre** il pattern osservato in un modulo esistente ben fatto rispetto a un'idea astratta di "come si dovrebbe fare".

---

## Procedura di rilevamento

1. **Inquadra il file/dir.** Che ruolo ha (Model? Controller? `config.php`? migration? Facade? Module?). Il ruolo determina quali script eseguire (§Regola mentale n.3) e quali skill satellite caricare per il residuo di giudizio.
2. **Esegui gli script pertinenti** e traduci ogni riga di `findings` in un finding (§Come si inseriscono nella procedura).
3. **Valuta il residuo di livello 1** (riuso, hardcode dubbio) non coperto dagli script.
4. **Passa il livello 2 (Laravel).** Solo su ciò che il livello 1 non copre già.
5. **Passa il livello 3 (generale/DRY).** Solo su ciò che i livelli sopra non coprono.
6. **Verifica prima di affermare.** Ogni finding manuale nasce dall'aver **aperto** il file coinvolto; quelli da script nascono dal loro output. Ciò che non hai verificato: o lo marchi "da verificare", o non entra.
7. **Ordina i findings** per gravità decrescente e restituiscili nel formato sotto.

---

## Gravità

- 🔴 **critico** — viola una convenzione master-core bloccante (UUID, classe base, `vendor/` toccato, namespace rotto) o un bug/rischio concreto.
- 🟡 **importante** — pattern sbagliato che funziona ma va contro convenzione/idioma (logica nel posto sbagliato, DB nel controller, validazione assente).
- 🟢 **suggerimento** — DRY/naming/pulizia; migliora ma non è vincolante.

---

## Formato del finding

Ogni discrepanza è un blocco:

```markdown
### [🔴|🟡|🟢] <titolo breve> — Livello <1 master-core | 2 Laravel | 3 generale>
- **Dove:** `path/al/file.php:line` (o range)
- **Problema:** cosa c'è e perché è una discrepanza (cita la regola/fonte: es. "script check-migrations §uuid-pk", "CLAUDE.md audit fields", "campo Select dovrebbe usare l'options provider — skill master-core-fields").
- **Correzione proposta:** cosa fare concretamente (dove spostare la logica, quale API usare). Se serve, snippet minimo.
- **Rischio della correzione:** basso/medio/alto + eventuali dipendenze (tocca DB? cambia firma pubblica? impatta produzione? vedi memoria `production-media-safety`).
- **Confidenza:** certa | da verificare (con la domanda aperta).
```

Alla fine, una riga di **riepilogo**: `N critici, M importanti, K suggerimenti` + eventuale nota "fuori ambito: <file non-PHP saltati>".

---

## Regole finali

- **Solo PHP/Laravel**, solo segnalazione, sola lettura. Niente scrittura, niente `docs/`, niente edit al codice.
- **Esegui gli script prima di valutare a mano** ciò che coprono — non ri-derivare a occhio una regola strutturale/comportamentale meccanica che uno script già verifica.
- **Non inventare convenzioni**: cita sempre la fonte (script o skill satellite). Nel dubbio → "da verificare".
- **Attribuisci ogni finding al livello più alto** che lo copre e rispetta l'ordine 1→2→3.
- **Non segnalare `vendor/`** come "da migliorare nel repo": i fix ai package si fanno altrove (`laravel-master-dev`); al più segnala che un file applicativo modifica/duplica logica del vendor.
- Preferisci il **pattern di un modulo esistente** all'astrazione teorica.
