# Scelta e potenziamento dei worker

Riferimento della skill `project-manager`. Da leggere **prima della prima
delega** di una sessione (§4 di `execution.md`). Copre: quale worker
scegliere, come potenziarlo, cosa iniettare obbligatoriamente, e come
evitare che due worker si pestino i piedi.

## 0. Questa pagina presume master-core/master-legacy

Se l'Ambiente dichiarato in Fase 0 è **generico** (fuori da master-\*), la
tabella del §1 e l'iniezione obbligatoria del §3 **non si applicano**: usa
`Explore`/`general-purpose` per scoperta e ricerca, `general-purpose`/`claude`
per implementazione, e verifica con l'utente (o nella Comprensione) quali
convenzioni proprie del progetto il worker deve seguire invece di
`master-code-review`. Il resto di questa pagina (§2 potenziamento, §4
conflitti, §5 contenuto del prompt) vale sempre, a prescindere dall'ambiente.

## 1. Scegli il worker più specializzato disponibile

Non delegare "in modo generico" per default: un worker specializzato porta
già in contesto le convenzioni giuste e costa meno giri.

| Attività | Worker |
|---|---|
| Esplorazione/scoperta legacy, mappatura EAV→Eloquent | `master-laravel-enesi-plugin:master-migration-analyst` |
| «Esiste già un pacchetto ufficiale per X?» | `master-laravel-enesi-plugin:master-package-scout` |
| Review di convenzioni (UUID, PSR-4, multilingua, struttura modulo) pre-commit | `master-laravel-enesi-plugin:master-reviewer` |
| Ricerca profonda nel codice del Master (incrociare `config.php` + `Classes/Module.php` + rotte + Model) | `master-search` |
| Creazione nuovo modulo CMS | segui il pattern di `master-laravel-enesi-plugin:master-new-module` |
| Ricerca/lookup mirato in sola lettura | `Explore` |
| Task multi-step ampio | `general-purpose` |
| Implementazione senza match specializzato | `general-purpose` o `claude` |

Se nessuno calza, `general-purpose` va bene — ma **dichiara nel prompt** cosa
deve restituire e con quale formato, altrimenti torna un tema libero.

## 2. Potenziamento: applica `subagent-empowerment`

Prima di emettere ogni chiamata `Agent`, applica la skill
**`subagent-empowerment`**, che governa:

- **modello** in base al livello di complessità (L1 leggero → `haiku`, fino
  ai livelli alti);
- **skill obbligatorie da iniettare** nel prompt del worker;
- **whitelist MCP** (non dare accesso a server MCP che il worker non usa);
- **tetto di concorrenza**: max **3 worker** in parallelo, max **1 Opus**
  alla volta;
- **permesso di scrittura su CLAUDE.md** (di norma negato).

Regola pratica: un worker **read-only** (scoperta/analisi/verifica) è per
definizione **L1** — modello leggero, nessun MCP se non serve, nessuna
scrittura.

## 3. Iniezione OBBLIGATORIA di `master-code-review`

Ogni worker che **crea o modifica codice PHP/Laravel** (Model, Controller,
`config.php`, migration, Facade, Classe Module, logica PHP nelle Blade)
**deve** caricare la skill **`master-code-review`** e produrre codice già
in linea col criterio: 1. master-core (priorità massima) → 2. best practice
Laravel → 3. best practice generali/DRY.

In concreto, il worker deve sapere già in partenza che sono errori: query o
array di opzioni costruiti dentro un `config.php` invece del canale previsto
dal framework; PK non-UUID, classi base sbagliate, audit fields non
conformi; rifare a mano ciò che un pacchetto ufficiale `laravel-master-*`
già copre.

Iniettala tra le skill obbligatorie del worker (via `subagent-empowerment`).
Ai worker in **sola lettura** non serve: non scrivono codice.

## 4. Conflitti tra worker in parallelo

Se più worker modificano file in parallelo e rischiano di sovrascriversi:

- **isolali** — `isolation: "worktree"` sulla chiamata `Agent`, così
  ciascuno lavora su una copia git separata; oppure
- **serializzali** — se il costo dell'isolamento non è giustificato.

Attenzione al caso subdolo: due worker che toccano lo stesso `config.php` o
la stessa migration. Non è un conflitto git astratto, è perdita di lavoro
reale. Se non sei sicuro che i loro insiemi di file siano disgiunti,
serializza.

## 5. Cosa deve contenere sempre il prompt di delega

Un worker sbaglia quasi sempre per contesto mancante, non per incapacità.
Ogni prompt dice:

1. Qual è il problema e perché lo stiamo risolvendo.
2. Cosa è già stato scoperto o deciso (così non ri-esplora e non ri-decide).
3. Cosa deve restituire, in quale formato.
4. Se deve solo cercare, o anche scrivere/modificare. Senza questa riga i
   worker sbagliano l'intento: un worker di analisi che crede di dover
   implementare fa danni.
5. Se serve documentazione (scoperta legacy o finale), dillo esplicitamente:
   la scrive il worker che ha fatto la scoperta, non tu.
