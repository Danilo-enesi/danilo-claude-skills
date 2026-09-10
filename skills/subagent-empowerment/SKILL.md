---
name: subagent-empowerment
description: Come loop principale (Orchestratore o Project Manager), prima di delegare lavoro a uno o più sottoagenti (tool `Agent` o `Workflow`), per decidere QUANTO potere dargli: quale modello, quali skill fargli caricare, quali MCP autorizzargli, se può scrivere su CLAUDE.md, e con quali tetti di concorrenza. Attivala quando pensi «creo un worker per…», «delego questa attività», «lancio N sottoagenti in parallelo», «che modello uso per questo agente», «quanti agenti alla volta». Regola guida: default POTERE MINIMO, si promuove solo con un innesco osservabile, con tetti duri di modello e concorrenza (mai far esplodere costi/macchina).
---

# Skill: Potenziamento dei sottoagenti (assegnazione dei "poteri")

## A cosa serve

Quando sei il **loop principale** (Orchestratore o Project Manager) e deleghi lavoro, ogni worker riceve dei "poteri": il **modello** con cui gira, le **skill** che carica, gli **MCP** che può interrogare, il **permesso di scrivere su CLAUDE.md**. Più poteri = più capacità *ma* più costo (token, tempo, rischio). Questa skill trasforma quella scelta da intuizione in una **procedura deterministica con tetti**, così il potenziamento è **utile e mantenibile** e non diventa una macchina che fonde il PC (es. 5 worker `fable` a `max` effort tutti insieme).

## Modello mentale (2 regole)

1. **Il default è POTERE MINIMO.** Un worker parte dal livello più basso; si **promuove** solo se un *innesco osservabile* lo richiede. Non si concede potere "per sicurezza".
2. **In dubbio tra due livelli → scegli quello più ALTO** (per il modello). In dubbio se concedere una capacità (MCP, scrittura CLAUDE.md) → **non concederla**. Le due regole tirano in direzioni opposte apposta: alzi la *qualità di ragionamento* quando serve, ma non allarghi la *superficie di azione* senza motivo.

## Checklist per OGNI worker (esegui prima di delegare)

Rispondi meccanicamente a queste 5 domande; l'output è `{ model, skill?, mcp?, scrittura_CLAUDE? }`.

1. **Scrive o solo legge?** Solo lettura/ricerca/esplorazione read-only → candidato **L1**.
2. **Quanti file/moduli tocca?** ≥3 file **oppure** ≥2 moduli → **L3**.
3. **C'è una di queste?** decisione di architettura/design · scoperta o mappatura master-legacy (EAV→Eloquent) · migrazione di dati · debug di un bug di cui **non** si conosce la causa → **L3**.
4. **Combacia con una skill del §Mappa skill?** → il prompt DEVE ordinare di caricarla.
5. **Serve un MCP della §Whitelist MCP?** → autorizzalo esplicitamente nel prompt; altrimenti nessuno.

Poi valuta la **scrittura su CLAUDE.md** (§CLAUDE.md) e il **tetto di concorrenza** (§Concorrenza) prima di emettere le chiamate.

## §1 — Modello per livello (Fable VIETATO)

Valuta i livelli **dall'alto in basso**; si applica il **primo** che combacia.

| Liv. | Innesco (basta UNO vero) | `model` | subagent_type tipico |
|---|---|---|---|
| **L3 — Pesante** | architettura/design; ≥3 file o ≥2 moduli; scoperta/mappatura master-legacy; migrazione dati; bug a causa ignota | `opus` | `master-laravel-enesi-plugin:master-migration-analyst`, `general-purpose` |
| **L2 — Standard** | scrittura/modifica che segue un pattern esistente o coperto da skill, in 1–2 file di un solo modulo, senza scelte architetturali | `sonnet` | `general-purpose`, `master-laravel-enesi-plugin:master-reviewer` |
| **L1 — Leggero** | SOLO lettura/ricerca/esplorazione read-only; rinomini o edit meccanici senza logica | `haiku` | `Explore`, `master-laravel-enesi-plugin:master-package-scout` |

- Il `model` si imposta **sempre** (`Agent` → campo `model`; `Workflow` → `agent(prompt, {model})`).
- **`fable` è vietato in automatico.** Usalo solo se l'utente lo chiede esplicitamente per un task specifico.
- **Fallback in dubbio**: L1 vs L2 → scegli **L2**; L2 vs L3 → scegli **L3**.

## §2 — Sforzo (effort)

- La leva è **solo il modello**. L'`effort` resta quello della **sessione**.
- Il tool `Agent` **non** ha un parametro `effort`: non provare a passarlo. L'effort per-worker esiste solo dentro `Workflow` (`agent(prompt, {model, effort})`), ma **in questo progetto non lo alziamo in automatico**: niente `high`/`xhigh`/`max` deciso da te. Se un task sembra richiederlo, la risposta è salire di **modello** (fino a `opus`), non di effort.

## §3 — Concorrenza (freno anti-blowup)

Prima di emettere chiamate `Agent` in parallelo, conta:

- **Massimo 3 worker in parallelo.**
- **Massimo 1 worker `opus` alla volta**: i task L3 si **serializzano** (aspetta che l'Opus in corso finisca prima di lanciarne un altro). Non lanciare mai 2+ Opus insieme.
- Se hai più di 3 attività pronte, **metti in coda** le eccedenti e lanciale man mano che si liberano gli slot.
- Regola pratica: parallelizza liberamente i worker `haiku`/`sonnet` (entro il tetto di 3), serializza gli `opus`.

## §4 — Mappa skill (lookup OBBLIGATORIO)

Se il task combacia con una riga, il prompt di delega DEVE contenere la frase esplicita: «**Invoca prima la skill `<nome>` e seguila.**» Non è a tua discrezione.

| Il task riguarda… | Skill che il worker DEVE invocare |
|---|---|
| creare un nuovo modulo CMS | `master-laravel-enesi-plugin:master-new-module` |
| aggiungere/modificare un campo in un `config.php` | `master-core-fields` |
| blocchi di contenuto (`page_contents` / `typo.html`) | `master-page-content` |
| migrare un HTML del template in una view Blade | `template-to-blade` |
| navigare/testare il sito front | `front-navigation` |
| errori/diagnostica del Master | `master-laravel-enesi-plugin:master-debug` |
| comandi artisan / pacchetti | `master-laravel-enesi-plugin:master-artisan` |
| review di convenzioni pre-commit | `master-laravel-enesi-plugin:master-review` |
| migrazione sito legacy | `master-laravel-enesi-plugin:master-migrate-legacy` |
| automazione browser reale | `master-laravel-enesi-plugin:agent-browser` |

Se nessuna riga combacia, non forzare alcuna skill.

## §5 — Whitelist MCP (autorizzazione chiusa)

Un worker può interrogare un MCP **solo** se il suo prompt lo nomina esplicitamente. Whitelist chiusa: nient'altro è autorizzato (Figma, Gmail, Asana, ecc. → mai, salvo richiesta esplicita dell'utente).

| Serve… | MCP | Frase da mettere nel prompt |
|---|---|---|
| documentazione/forum interni Enesi | Enesi Academy | «Puoi consultare l'MCP *Enesi Academy* per la documentazione.» |
| ambiente locale Dunebox (host, php, log, db) | dunebox | «Puoi usare l'MCP *dunebox* per l'ambiente locale.» |
| navigazione browser reale | claude-in-chrome | «Puoi usare l'MCP *claude-in-chrome* per il browser.» |

Se il task non ne ha bisogno, **non** autorizzare alcun MCP.

## §6 — Scrittura su CLAUDE.md (un worker alla volta)

Un worker **può** annotare su CLAUDE.md fatti ricorrenti utili, ma in modo controllato:

- **Concedi il permesso a UN SOLO worker alla volta.** Mai a due worker in parallelo (evita conflitti di scrittura sullo stesso file). Il permesso esiste solo se il prompt di delega lo dà esplicitamente: «**Sei autorizzato ad annotare in CLAUDE.md**, in append, secondo i criteri della skill `subagent-empowerment`.»
- Il worker può scrivere **solo in append** (mai cancellare o riscrivere righe esistenti), max **3 righe**, nella sezione pertinente; se non esiste, sotto una sezione `## Note operative`.
- **Qualifica**: annota solo se sono vere **TUTTE**:
  1. è un fatto **durevole** sul codebase/convenzioni (non sul task corrente);
  2. gli è servito ≥2 volte, oppure trovarlo è costato più di un giro di esplorazione;
  3. non è già scritto in CLAUDE.md né in una skill esistente.
  Se anche una sola è falsa → niente annotazione.

## Anti-pattern (cosa NON fare)

- ❌ Lanciare più worker `opus` (o peggio `fable`) in parallelo "per andare più veloce". ✅ 1 Opus alla volta, max 3 worker totali.
- ❌ Alzare l'`effort` a `high`/`xhigh`/`max` di tua iniziativa. ✅ Effort = sessione; sali di **modello**, non di effort.
- ❌ Dare `opus` a un task di sola lettura/esplorazione. ✅ Read-only = L1 = `haiku`.
- ❌ Autorizzare MCP o scrittura CLAUDE.md "in caso servano". ✅ Solo se il task li richiede davvero, nominati nel prompt.
- ❌ Far scrivere CLAUDE.md a due worker in parallelo. ✅ Uno alla volta, in append.
- ❌ Concedere una skill sbagliando la riga della mappa, o dimenticare di iniettarla quando la riga combacia. ✅ Lookup meccanico nel §4.

## Come la usano PM e Orchestratore

- **Orchestratore**: al passo «delega» della pipeline, per **ogni** worker esegui la Checklist e applica §1–§6 prima di emettere la chiamata `Agent`/`Workflow`.
- **Project Manager**: i sottoagenti di **validazione dei presupposti** (Fase 0) sono per definizione **read-only → L1 → `haiku`**, senza MCP né scrittura CLAUDE.md. Quando passi in modalità Orchestratore per eseguire, applichi la skill come sopra.
- Questa skill è la **fonte unica** delle regole di potenziamento: se cambia un tetto o una tabella, si modifica qui, non nei comandi.
