# Come funziona il sistema "Contents" — le 4 capa

Il campo `Contents` NON è un unico meccanismo monolitico: sono **4 capa distinte**, ognuna con le sue classi, il suo punto di estensione, e il suo modo di essere sbagliata. Capire quale capa stai toccando è la differenza tra un fix di 5 minuti e un pomeriggio a indovinare perché "non salva".

```
1. FIELD & TOOLBAR   → cosa vede l'admin quando apre il tab "Contenuti"
2. EDITOR WIDGET      → l'input HTML di UN blocco dentro il form (summernote, select, media...)
3. AJAX DISPATCH       → cosa succede quando l'admin clicca "Aggiungi blocco" (nessun submit del form)
4. PERSISTENZA         → cosa succede al submit del form (saveData)
5. LETTURA FRONTEND    → come il front legge i blocchi salvati (getBlockData/getContentMedia)
```

Le capa 1-2-4 sono **package** (`vendor/enesisrl/laravel-master-core`), quasi sempre condivise da TUTTI i moduli che usano `Contents`. La capa 3 ha **un solo punto realmente per-modulo**, ed è quello che si rompe più spesso quando installi il sistema su un modulo nuovo (vedi `install-non-conventional.md`).

---

## Capa 1 — Field & Toolbar

**Classe:** `Enesisrl\LaravelMasterCore\Foundation\Form\Fields\Contents` (estesa a livello app in `Master\Foundation\Form\Fields\Contents`).

Cosa fa `render()`:
1. Crea un tab Bootstrap per ogni lingua front (`Websites::current("frontLanguages")`).
2. Dentro ogni tab, renderizza la **toolbar** ("Aggiungi blocco") — una view Blade, non hardcoded qui.
3. Legge i blocchi esistenti con **`$this->model->page_contents($lang)`** (nota: chiama letteralmente il metodo `page_contents()` sul model, indipendentemente dal nome del modulo — vedi §"Il nome del metodo è fisso" più sotto) filtrati `draft=0`, ordinati per `sequence`.
4. Per ogni blocco, istanzia la classe "editor widget" corrispondente al `type` (switch fisso a 6 casi — capa 2) e ne chiama `render()`.
5. Se il `type` non è tra i 6 standard, delega a **`getCustomContents()`** — hook vuoto nel package, sovrascritto a livello app per i tipi custom (es. `image_full`).

**Config chiave del field** (in `config.php`, `$form->addField('Contents', [...])`):

| Config | Serve a | Default |
|---|---|---|
| `name` | nome HTML del field (di solito `'contents'`) | — |
| `moduleName` | **SOLO** per il dispatch AJAX (capa 3) — quale content-model creare quando si aggiunge un blocco | `null` → risolve a `PageContent` |
| `contentConfigs` | override/merge delle config per tipo (editor summernote, `maxNumberOfFiles`, opzioni select...) sopra `config('master.contentConfigs')` | `config('master.contentConfigs')` |
| `viewsModuleName` | namespace Blade per **toolbar + partial dell'editor widget** (capa 2) | `"CrudModulePreset"` |
| `toolbarViewsModuleName` | namespace Blade solo per la toolbar (raramente diverso da `viewsModuleName`) | `"CrudModulePreset"` |

> ⚠️ **`moduleName` e `viewsModuleName` NON sono la stessa cosa, nonostante il nome simile.** `moduleName` è un identificatore libero (`"ProjectsModule"`, `"BlogModule"`) usato in UN SOLO punto: lo switch dentro `newContent()` (capa 3). `viewsModuleName` è un **namespace di view Blade reale** (risolto dal service provider del modulo verso `Views/`), usato per renderizzare la toolbar e il partial condiviso `contents.base.content`. In pratica: quasi **nessun modulo cambia `viewsModuleName`** (tutti usano il default `CrudModulePreset`, cioè le view app-level in `Foundation/Modules/Crud/Views/contents/`) — l'unico che cambia sempre è `moduleName`.

**Il nome del metodo relazione è fisso — `page_contents()`, sempre.** Anche se il tuo modulo si chiama "Products" e la tua tabella è `product_contents`, il metodo Eloquent sul model DEVE chiamarsi `page_contents($language)` — è il nome che la capa Field e la capa Persistenza chiamano letteralmente via `$this->page_contents(...)`. Non è configurabile, non c'è un `contentRelationName` da impostare. Rinominarlo rompe silenziosamente sia la lettura in admin sia il cleanup dei blocchi obsoleti al salvataggio.

---

## Capa 2 — Editor widget (l'input di UN blocco nel form admin)

**Classe base:** `Enesisrl\LaravelMasterCore\Foundation\Form\Content` (estesa a livello app in `Master\Foundation\Form\Content`, quasi sempre vuota).

**Non confondere con i componenti Blade del frontend** (`TestoBlock`, `PhotogalleryBlock`...) — sono due gerarchie di classi completamente separate che condividono solo il nome del `type`. Questa capa produce l'HTML dell'**editor** in admin (textarea summernote, select, upload media); l'altra (vedi `frontend-convention.md`) produce l'HTML **pubblico**.

Le 6 classi standard vivono in `Master\Foundation\Form\Contents\{Title,Text,Article,Gallery,Attachment,VideoEmbed}` (override app-level di `Enesisrl\LaravelMasterCore\Foundation\Form\Contents\*`), più `ImageFull` (custom, solo app-level — non esiste nel package).

Ogni istanza riceve nel costruttore: `($viewsModuleName, $lang, $cont, $content, $contentConfigs)` dove:
- `$viewsModuleName` → il namespace Blade (da capa 1), qui esposto come `$this->moduleName` **dentro questa classe** — sì, è un'altra collisione di nome: la property si chiama `moduleName` ma il valore che riceve è `viewsModuleName`. Non è il `moduleName` del dispatch.
- `$content` → l'istanza del content-model (es. `PageContent`/`ProjectContent`), esposta come `$this->model`.
- `$contentConfigs` → array di config per-tipo, letto via `$this->config('chiave')`.

Metodi che una sottoclasse tipicamente ridefinisce:
- `register()` — costruisce una `Form` interna e aggiunge i sotto-campi (es. `Text::register()` aggiunge un `Text` con editor summernote; `Gallery`/`Attachment`/`Article` aggiungono anche un campo `MediaLibrary`).
- `render()` — produce l'HTML finale, tipicamente `view($this->moduleName . '::contents.base.content', [...])` — cioè il partial condiviso `contents/base/content.blade.php` risolto nel namespace `viewsModuleName` (default `CrudModulePreset`), che disegna la card con titolo/drag-handle/pulsante-rimuovi comuni a tutti i tipi.
- I `name` HTML dei sotto-campi seguono SEMPRE la convenzione `content<Chiave>__<lang>[<cont>]` (es. `contentText__it[3]`, `contentOption__it[3]`) — è quello che `saveData()` (capa 4) si aspetta di leggere da `request()`. Sbagliare questo pattern significa che il campo si vede in admin ma **non salva nulla**.

Per il catalogo completo dei tipi e come estenderli/aggiungerne uno nuovo → **`references/conventional-blocks.md`**.

---

## Capa 3 — Dispatch AJAX ("Aggiungi blocco" senza submit del form)

Quando l'admin clicca una voce della toolbar, JS invia `POST /services/addContent` (`data-admin-add-content='{"type":...,"moduleName":...}'`). Flusso:

```
Services\AdminController::addContent()          [app-level, in Modules/Services/Controllers/]
  ├─ tipo standard (title/text/article/gallery/attachments/video_embed)
  │    └─▶ parent::addContent()                  [core: Foundation/Modules/Crud/Controllers/AdminController]
  │           ├─ $this->newContent($model_id, $type)     ← chiama la versione APP-LEVEL overridden
  │           └─ $this->createContentInstance($content, $request)
  │                  └─ switch($type) su 6 classi fisse (Title/Text/Gallery/Attachment/Article/VideoEmbed)
  │                     + requiresMediaId($type) per gallery/attachments/article
  └─ tipo custom (es. image_full, in $customTypes)
       └─▶ gestito qui direttamente:
              $this->newContent($model_id, $type)         ← STESSA funzione app-level
              new \Master\Foundation\Form\Contents\ImageFull(...)
```

**`newContent()` è il SINGOLO punto d'integrazione per-modulo, e sia il percorso standard sia quello custom lo condividono** (polimorfismo: `parent::addContent()` chiama `$this->newContent()`, che risolve alla versione app-level per via dell'ereditarietà). La sua implementazione è uno switch fisso su `moduleName`:

```php
// Master\Modules\Services\Controllers\AdminController::newContent()
switch (request()->input("moduleName")) {
    case "BlogModule":
        return \Master\Modules\Blog\Models\BlogContent::create([...]);
    case "ProjectsModule":
        return \Master\Modules\Projects\Models\ProjectContent::create([...]);
    default:
        return \Master\Modules\Pages\Models\PageContent::create([...]); // ⚠️ fallback silenzioso
}
```

> ⚠️ **Non c'è auto-discovery.** Aggiungere un modulo al sistema Contents richiede di aggiungere a mano un `case` qui. Se lo salti, ogni "Aggiungi blocco" sul modulo nuovo cade nel `default` e crea una riga in `page_contents` con `page_id` impostato all'id **del tuo model** (che magari nemmeno esiste in `pages`) — nessun errore visibile, il blocco semplicemente non appare mai (o peggio, sporca `page_contents`). Vedi `install-non-conventional.md` per la procedura completa.

I 6 tipi standard in `createContentInstance()` sono una **mappa fissa nel package** — non estensibile via config. Un tipo nuovo (7°) può esistere SOLO passando per il hook custom (`getCustomContents()` + `$customTypes` in `addContent()`), esattamente come `image_full`. Vedi `conventional-blocks.md`.

---

## Capa 4 — Persistenza (submit del form)

**Metodo:** `saveData()` sul model principale (definito in `Enesisrl\LaravelMasterPages\Modules\Pages\Models\Page`, ereditato — quando il model estende `Page`; se il model estende già un altro model di package, l'equivalente si richiama a mano tramite il trait `HasContentBlocks`, vedi `install-non-conventional.md` §3B).

A differenza della capa 3, questa parte **è già generica** — legge `$this->contentClass` e `$this->content_foreign_key` (le due property che dichiari nel tuo model) invece di avere nomi hardcoded:

```php
public function saveData() {
    parent::saveData(); // salva colonne/traduzioni/valori del model principale
    foreach (Websites::current("frontLanguages") as $lang) {
        // legge contentId__it[], contentSequence__it[], contentType__it[], contentText__it[], contentOption__it[] da request()
        // per ogni indice: crea/aggiorna una riga di $this->contentClass
        //   $page_content->{$this->content_foreign_key} = $this->id;
        // le righe NON presenti nell'array ricevuto vengono forceDelete()
    }
}
```

Chiavi che legge SEMPRE da `request()`, per ogni lingua: `contentId`, `contentSequence`, `contentType`, `contentText`, `contentOption` (più eventuali chiavi extra via `getCustomData()`, hook che ogni model può sovrascrivere — vedi l'esempio reale in `Pages\Models\Page::getCustomData()` per `style`/`layout`/`color`/`body`/`caption`).

**Reconciliazione totale**: ad ogni salvataggio, i blocchi non ripresentati nel POST vengono `forceDelete()`-ati leggendo `$this->page_contents($lang)->where("draft",0)`. Questo È il motivo per cui `page_contents()` (capa 1) deve puntare alla tabella giusta — se resta sul default (`PageContent`/`page_id`), il cleanup cancella righe a caso in `page_contents`, non nella tua tabella.

---

## Capa 5 — Lettura frontend

**Classe base content-model:** `Enesisrl\LaravelMasterPages\Modules\Pages\Models\PageContent` (estesa a livello app come `Master\Modules\Pages\Models\PageContent`, e da lì da ogni content-model specifico: `BlogContent`, `ProjectContent`, ecc.).

> **Estendere questa classe NON crea alcun legame con la tabella `page_contents` né con il model `Page`.** `$table` è una property sovrascritta (`BlogContent`/`ProjectContent`/... impostano la propria), e Eloquent legge sempre la property dell'istanza reale — la tabella del padre non viene mai interrogata. L'unico riferimento a `Page::class` in tutta la classe è il metodo `page(): BelongsTo` (una `belongsTo` di comodo, non usata da nessun'altra parte del sistema Contents), e anche quello lo sovrascrivi puntando al tuo model. L'unico requisito reale per estendere `PageContent` è che quella **classe PHP** esista (cioè il modulo Pages sia installato nel progetto) — un requisito di codice, non sui dati.

Due metodi, entrambi generici (non hanno bisogno di override):

```php
$block->getBlockData('text')                 // legge $block->data['text'] (cast json→array)
$block->getContentMedia('Gallery')           // Spatie: collection 'content' . $tipo . '__' . $block->data['media_id']
```

`getContentMedia($tipo)` costruisce il nome collection concatenando **il parametro che gli passi** (non il `type` del blocco) con `media_id`. Il parametro dev'essere identico a quello usato lato admin quando la collection è stata registrata (vedi `Gallery`/`Attachment`/`Article` in `conventional-blocks.md`) — sono stringhe libere per convenzione (`Gallery`, `Attachment`, `Article`, `ImageFull`), non enum.

**Accesso ai blocchi dal model principale:** `$model->blocks` — accessor `getBlocksAttribute()`, che (come `page_contents()`) è **hardcoded** nella classe base a `PageContent::where("page_id", $this->id)...` e va **sempre** sovrascritto in ogni model che ha un `$contentClass` diverso (vedi il gotcha in `install-non-conventional.md`).

---

## Schema tabella `<entity>_contents`

Identico in tutti i moduli esistenti (Pages/Blog/Projects) — copialo esattamente per un modulo nuovo:

| Colonna | Tipo | Note |
|---|---|---|
| `id` | `uuid` PK | |
| `<entity>_id` | `string(36)` index | FK → tabella principale, `onDelete CASCADE` |
| `draft` | `boolean` nullable, index | `1` = bozza pre-salvataggio, `0` = live |
| `lang` | `string(5)` | una riga per lingua |
| `type` | `string(50)` index | discriminatore |
| `sequence` | `integer` nullable, index | ordinamento |
| `data` | `json` nullable | payload libero, cast `array` |
| timestamps + `deleted_at` | | il cleanup usa comunque `forceDelete()`, non soft-delete |

**Niente audit fields** (`created_by`/`updated_by`/`deleted_by`) su questa tabella in nessuno dei 3 moduli esistenti — solo sulla tabella principale.
