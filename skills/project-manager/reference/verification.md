# Verifica — fase automatica, a tier proporzionali

Riferimento della skill `project-manager`. Leggilo al passo 8 di
`execution.md`, quando l'esecuzione è conclusa e prima della Validazione del
risultato. È una fase di **questo stesso flusso**, non una modalità a parte
da invocare a mano: gira sempre, salvo lavoro puramente documentale o rinuncia
esplicita dell'utente.

## Perché a tier, e non "decidi tu quanto verificare"

Lasciare alla verifica il compito di decidere da sola cosa e quanto
controllare è la causa più diretta di token bruciati senza risultato: si
finisce per ragionare da zero ogni volta su "cosa si può testare qui". Per
evitarlo, **il tier lo sceglie chi pianifica**, non chi verifica:

- Il tier di default si legge da **"File/moduli attesi"** dichiarato in
  ciascuna voce di `docs/asked/<slug>.md` §2 (`templates/task.md`).
- Il campo **`Verify`** di ogni voce, scritto al momento della pianificazione
  (`execution.md` passo 2), è un **contratto**: la verifica esegue quello che
  è scritto, non lo inventa. Se `Verify` dice "n.a. — fase documentale", non
  si verifica nulla per quella voce.
- Il giudizio agentico si applica solo per **interpretare un esito** (perché
  fallisce, cosa significa), mai per decidere da zero cosa eseguire.

## Se l'ambiente è generico (fuori da master-\*)

I comandi concreti dei tier e dei pilastri sotto sono i default per
master-core/master-legacy (artisan, Pint, `master-reviewer`). Se l'Ambiente
dichiarato in Fase 0 è **generico**, sostituiscili con quelli accertati in
`templates/comprehension.md` ("Convenzioni del progetto"): comando build al
posto di `migrate --pretend`, comando test del progetto al posto di
`php artisan test`, il suo linter/formatter al posto di Pint, e un
worker/skill di review del suo stack (se noto) al posto di
`master-reviewer`/`master-code-review` per il pilastro 2 — altrimenti
ometti il pilastro 2 dichiarandolo `n.a. — nessun criterio di convenzioni
noto per questo progetto`, non inventarne uno.

## I tre tier

| Tier | Quando (da "File/moduli attesi") | Cosa gira | Note |
|---|---|---|---|
| **Smoke** (default) | 1–3 file, cambio di config/campo/testo | `php -l` sui file toccati; `php artisan migrate --pretend` se c'è una migration; suite esistente se esiste (`php artisan test`) | Solo comandi deterministici, nessuna esplorazione agentica |
| **Focused** | 4+ file, o tocca logica di business | Smoke + 1 worker L1 con `master-code-review` sui file toccati + verifica dei percorsi/comandi dichiarati in `Verify` per quella voce | Acotato a ciò che il piano ha già elencato, non esplorazione libera |
| **Full** | Solo se l'utente lo chiede esplicitamente, o il piano marca la voce come critica | I quattro pilastri sotto, per intero, incluso browser se Dunebox è su | Opt-in esplicito — non è il default nemmeno per cambi grandi se nessuno lo ha chiesto |

Se una voce del piano non dichiara "File/moduli attesi" (piano senza quel
dettaglio), tratta il tier come **Smoke** per default — mai come Full per
eccesso di prudenza: un gate costoso che si applica senza motivo è tempo
bruciato quanto uno saltato per pigrizia.

## I quattro pilastri (usati per intero solo in tier Full; Focused ne usa un sottoinsieme dichiarato sopra)

Non inventare nuove verifiche: quelle che servono esistono già in questo
ecosistema. Il valore di questa fase è eseguirle nell'ordine giusto e
aggregare l'esito.

### 1. Si esegue davvero? — l'80% del valore

Il comando artisan interessato parte senza eccezioni; la migration applica
(e il rollback non esplode, se rilevante); la rotta/pagina admin risponde
200; il modulo appare nell'admin e il form si apre dopo un campo aggiunto.
Dopo modifiche a config/moduli: `php artisan config:clear` (+ `view:clear`
se serve) e ricontrolla — una cache stale produce falsi positivi e falsi
negativi. Tutto da `private/`. **Evidenza = comando + output reale**, mai
"dovrebbe funzionare".

Se non puoi verificare qualcosa (nessun browser, sito non raggiungibile,
dato di seed mancante), **non dedurre l'esito dal codice**: mettilo sotto
"Richiede validazione dell'utente" nell'acta, con i passi eseguibili, e
dillo anche nella risposta.

### 2. È allineato al master-core?

Delega a `master-laravel-enesi-plugin:master-reviewer` (parallelo, per file
o gruppo coerente), criterio `master-code-review`. Riporta i findings con
gravità (🔴/🟡/🟢) e livello (1 master-core/2 Laravel/3 generale) senza
riclassificarli. Un finding "da verificare" resta tale.

### 3. Formattazione (Pint) — solo se il progetto lo ha

Verifica prima che esista (`grep pint private/composer.json`). Se non c'è:
`n.a. — non installato in questo progetto`, non un fallimento. Da
`private/`: `./vendor/bin/pint --test <file>` per segnalare senza
riformattare — applicarlo è una correzione, vale il principio "non correggi
in prima persona" sotto.

### 4. Test automatici — ultimo, con onestà brutale

**Regola dura**: una suite verde non significa nulla se non contiene test
che coprono il lavoro appena svolto. Riporta sempre il numero di test
**rilevanti al cambiamento**, non solo "suite verde". Con zero test
rilevanti l'esito è **"nessuna copertura"**, mai "i test passano". Se i test
esistono, eseguili (`php artisan test` da `private/`) e riporta l'esito
reale; se non esistono, dillo — è informazione utile, non una colpa da
nascondere.

## Non correggi in prima persona

Chi verifica non può essere chi aggiusta. Se serve una correzione, delegala
a un worker (istruito a caricare `master-code-review`, con il finding
preciso) e poi ri-verifica. **Massimo 2 giri** di correggi→ri-verifica; al
terzo, fermati ed escala nella Validazione (`validation.md`) — non è un
dettaglio, è qualcosa di strutturale. Mai toccare `vendor/`: un difetto lì
va segnalato come fix da fare in `laravel-master-dev`. Non trasformare un
blocco reale in un verde forzato.

## Evidenza prima dell'affermazione

Ogni riga del report è ancorata a qualcosa di osservato: comando + output,
`file:line`. Dichiara sempre cosa **non** hai verificato e perché. Un report
che tace le lacune trasferisce all'utente un rischio silenzioso.

## Scrivi l'acta — `docs/tested/<data>-<slug>.md`

Stesso slug di `docs/asked/`. Un'acta, non un report di qualità: cosa hai
verificato, con quale evidenza, cosa hai trovato. Riporta l'esito anche
**inline** nella risposta.

```markdown
# Verifica — <titolo del lavoro>

> Tier: smoke | focused | full. Ambito: <cosa è stato verificato>.

**Verdetto: ✅ passa | ⚠️ passa con riserve | ⛔ non passa**

| Pilastro | Esito | Evidenza |
|---|---|---|
| 1. Si esegue | ✅ / ⚠️ / ⛔ | <comando + output reale> |
| 2. Allineamento master-core | ✅ / ⚠️ / ⛔ / n.a. (tier smoke) | <n. findings 🔴/🟡/🟢> |
| 3. Pint | ✅ / ⚠️ / n.a. | <esito, o "non installato"> |
| 4. Test automatici | ✅ / ⚠️ / nessuna copertura / n.a. (tier smoke) | **n. test rilevanti: N** |

### Bug e blocchi
- 🔴/🟡/🟢 <cosa non funziona> — `file:line` — <come riprodurlo>

### Correzioni delegate in questa fase
- <finding> → <cosa ha fatto il worker> → <esito della ri-verifica>

### ⚠️ Richiede validazione dell'utente
- <cosa validare> — **come:** <passi eseguibili> — **perché non l'ho fatto io:** <motivo>

### NON verificato (e perché)
- <cosa> — <fuori dal tier scelto / fuori ambito>
```

**Semantica del verdetto**: `⛔ non passa` = il lavoro non è pronto per
essere chiuso — dillo esplicito nella Validazione. `⚠️ passa con riserve` =
il lavoro sta in piedi ma restano findings o validazioni in mano
all'utente. Se c'è anche una sola voce sotto "Richiede validazione
dell'utente", il verdetto non può essere ✅.

## Cosa NON fare

- correggere codice in prima persona;
- modificare `vendor/`;
- scrivere fuori da `docs/tested/<slug>.md`;
- dichiarare "i test passano" quando non c'è copertura sul lavoro svolto;
- riportare come verificato ciò che hai solo letto;
- dedurre dal codice un esito che andava provato — se non puoi provarlo,
  passalo all'utente;
- omettere la sezione "NON verificato";
- inventare convenzioni di test non ancora decise;
- forzare un verde per chiudere prima;
- ri-fare la verifica di veridicità che ha già fatto `execution.md` passo
  6 — partine, non ripeterla;
- scegliere un tier più alto di quello che "File/moduli attesi" indica,
  "per sicurezza": il costo va giustificato dal piano, non da un impulso
  della verifica.
