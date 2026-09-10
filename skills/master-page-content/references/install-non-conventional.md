# Installare i blocchi di contenuto su un modulo NON convenzionale (es. Products)

"Non convenzionale" = un modulo che non arriva da un package dedicato pensato per i blocchi (`laravel-master-pages`, `laravel-master-blog`) ma vuole gli stessi blocchi di contenuto — es. `Products`, `Services`, qualsiasi CRUD di progetto.

> Prima di iniziare, leggi `references/package-internals.md` — qui si applicano le regole lì descritte, non le si ri-spiega.

---

## Il contratto reale (non è "estendi Page")

`Page` (`Master\Modules\Pages\Models\Page`) non è magia — è solo `Master\Foundation\Modules\Base\Models\Model` **più** queste 4 cose:

1. `protected string $contentClass` — quale content-model usare.
2. `protected string $content_foreign_key` — nome della colonna FK.
3. `page_contents($language)` — relazione `HasMany` verso `$contentClass`.
4. `getBlocksAttribute($language)` — accessor `->blocks`, stessa query senza filtro `draft`... con filtro `draft=0`.

Più, opzionalmente, `getCustomData()` (hook per campi extra) e l'integrazione nel flusso di `saveData()`.

**"Estendere `Page`" è SOLO UNO dei due modi di soddisfare questo contratto — quello che funziona quando il tuo model non ha già un genitore obbligato.** Blog e Projects lo fanno perché non hanno un package concorrente da cui derivare (Projects è un modulo di progetto "vuoto"; Blog ha un package dedicato che è stato scritto fin dall'inizio per estendere Page). **Non generalizza**: se il tuo model estende già un altro model di package — es. `Products` reale con `laravel-master-ecommerce` installato, dove `Master\Modules\Products\Models\Product extends Enesisrl\LaravelMasterEcommerce\Modules\Products\Models\Product` — PHP non permette di infilare `Page` anche nella catena: non c'è ereditarietà multipla, e comunque non vorresti alterare la semantica di un model che il package ecommerce già gestisce.

**La soluzione generale è un trait**, non l'ereditarietà. Il resto di questo file usa `Products` (con package ecommerce reale) come caso guida perché è il caso che rompe l'assunzione "estendi Page" — se il tuo modulo NON ha un genitore di package concorrente, il Percorso A (più corto) resta legittimo.

---

## Prima di tutto: quale percorso ti serve?

**Percorso A — nessun genitore di package concorrente.** Il tuo model non estende già un model fornito da un altro `laravel-master-*` (estende solo la `Model` base, o non estende nulla di specifico). → estendi direttamente `Master\Modules\Pages\Models\Page`.

**Percorso B — il model estende già un model di un altro package** (ecommerce Products, o qualsiasi model che arriva "pronto" da un package con la sua identità). → usa il trait `HasContentBlocks` (lo crei una volta a livello progetto, si riusa per ogni modulo in questa situazione).

I passi 1, 2, 4, 5, 6, 7 sono **identici** nei due percorsi. Solo il passo 3 (model principale) cambia.

---

## Checklist rapida

- [ ] 1. Migration: tabella `product_contents`
- [ ] 2. Content model: `ProductContent`
- [ ] 3. Model principale — **A** (estendi `Page`) oppure **B** (trait `HasContentBlocks`)
- [ ] 4. `config.php`: campo `Contents` + tab
- [ ] 5. **`Services\AdminController::newContent()`** — il case che quasi tutti si scordano
- [ ] 6. (solo se servono) tipi custom — nessuna azione extra, funzionano già
- [ ] 7. Verifica end-to-end

---

## 1. Migration

Copia esattamente lo schema di `page_contents` (vedi `package-internals.md` §Schema), cambiando solo il nome della FK:

```php
Schema::create('product_contents', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->string('product_id', 36)->index();
    $table->boolean('draft')->nullable()->index();
    $table->string('lang', 5);
    $table->string('type', 50)->index();
    $table->integer('sequence')->nullable()->index();
    $table->json('data')->nullable();

    $table->timestamps();
    $table->index(['created_at', 'updated_at']);
    $table->softDeletes()->index();

    $table->foreign('product_id', 'pdc_fk')
        ->references('id')->on('products')
        ->onUpdate('RESTRICT')->onDelete('CASCADE');
});
```

Metti la `Schema::dropIfExists('product_contents')` nel `down()` **prima** di droppare `products` (rispetta l'ordine delle FK).

---

## 2. Content model — `ProductContent`

Identico in entrambi i percorsi. Estende `Master\Modules\Pages\Models\PageContent` (l'override **app-level** — questa classe NON ha il problema del genitore concorrente, perché `PageContent` non porta nessuna identità di modulo, è puro storage di blocchi):

```php
<?php

namespace Master\Modules\Products\Models;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Master\Modules\Pages\Models\PageContent as Model;

class ProductContent extends Model
{
    protected $table = 'product_contents';

    protected $fillable = [
        'product_id',
        'draft',
        'lang',
        'type',
        'sequence',
        'data',
    ];

    protected $casts = [
        'data' => 'array',
    ];

    public function page(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id', 'id');
    }

    public static function getContentConfigs(): array
    {
        $configs = config('master.contentConfigs');

        // eventuali override specifici (editor, opzioni select, ecc.)
        $configs['contentText']['editor'] = 'summernote';
        $configs['contentArticleText']['editor'] = 'summernote';

        return $configs;
    }
}
```

Il metodo si chiama `page()` per convenzione (anche `BlogContent`/`ProjectContent` lo chiamano così, non `product()`) — non è usato attivamente dal sistema Contents ma tienilo coerente con gli altri content-model del progetto.

> **`product_contents` e `page_contents` sono tabelle completamente indipendenti — estendere `PageContent` non crea alcun legame tra le due.** `$table` è una property, non un valore "ereditato in senso forte": quando la sovrascrivi (`protected $table = 'product_contents';`), da quel momento **ogni** query fatta tramite `ProductContent` (incluse quelle dentro `getBlockData()`, `getContentMedia()`, `addData()`, ereditate senza modifiche) usa `$this->getTable()`, che legge la property dell'istanza reale — mai quella del padre. La tabella `page_contents` non viene mai toccata, letta, né deve contenere righe, né deve nemmeno esistere popolata: l'unico requisito reale è che la **classe PHP** `Master\Modules\Pages\Models\PageContent` esista nel progetto (cioè che il modulo Pages sia installato) — un requisito di codice da cui erediti dei metodi, non un requisito sui dati. `product_contents` esiste perché **tu** la crei con la migration del passo 1: non c'è nessuna generazione automatica legata all'ereditarietà.
>
> Stessa logica per `page()` (sopra): l'unico punto in cui `PageContent` menziona `Page::class` in tutto il file è quella riga, e la sovrascrivi puntando a `Product::class` — Eloquent non richiede che il modello di destinazione di una `belongsTo()` sia una sottoclasse di niente in particolare, quindi non c'è nessun vincolo residuo che ti costringa a far estendere `Page` al model principale.

---

## 3A. Model principale — Percorso A (estendi `Page`)

Usa questo percorso solo se `Product` non estende già un model di un altro package.

```php
<?php

namespace Master\Modules\Products\Models;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\App;
use Master\Modules\Products\Models\ProductContent;

class Product extends \Master\Modules\Pages\Models\Page
{
    // ... $table, $fillable, $casts del tuo modulo ...

    protected string $contentClass = ProductContent::class;
    protected string $content_foreign_key = 'product_id';

    /**
     * OBBLIGATORIO: il metodo base (Page::page_contents) è hardcoded su
     * PageContent/page_id e ignora $contentClass/$content_foreign_key.
     */
    public function page_contents($language = null): HasMany
    {
        $language ??= App::getLocale();

        return $this->hasMany(ProductContent::class, 'product_id', 'id')
            ->where('lang', '=', $language);
    }

    /** OBBLIGATORIO: stessa ragione — usato dal FRONTEND via $product->blocks. */
    public function getBlocksAttribute($language = null): Collection
    {
        $language ??= App::getLocale();

        return ProductContent::where('product_id', $this->id)
            ->where('lang', '=', $language)
            ->where('draft', 0)
            ->orderBy('sequence', 'asc')
            ->get();
    }

    /** Facoltativo — parent::saveData() (di Page) è già generico. */
    public function saveData(): bool
    {
        return parent::saveData();
    }

    /** Solo se un blocco ha campi extra oltre a text/option. */
    public function getCustomData($arr_data, $lang, $i): array
    {
        return $arr_data;
    }
}
```

> **Perché due override quasi identici (`page_contents()` e `getBlocksAttribute()`)?** Non è ridondanza evitabile: il primo serve all'ADMIN (Field, capa 1, e cleanup in `saveData()`, capa 4), il secondo al FRONTEND (`$model->blocks`, capa 5). Sono due letture indipendenti nel codice del package — se salti uno dei due, quella metà del sistema resta silenziosamente sulla tabella `page_contents`.

Salta al passo 4.

---

## 3B. Model principale — Percorso B (trait `HasContentBlocks`)

Usa questo percorso quando `Product` estende già un model di un altro package (`Enesisrl\LaravelMasterEcommerce\...\Product`, o analogo) e non puoi/non vuoi toccare quella catena di eredità.

### 3B.1 Crea il trait una volta a livello progetto

Se non esiste ancora, crealo in `master/Foundation/Modules/Base/Traits/HasContentBlocks.php` (stessa collocazione di `HasAddresses`, per coerenza — vedi la skill `master-core-fields` §2 per il pattern gemello). **Va scritto una sola volta per progetto**: qualsiasi altro modulo nella stessa situazione (un altro model con genitore di package concorrente) lo riusa.

```php
<?php

namespace Master\Foundation\Modules\Base\Traits;

use Illuminate\Database\Eloquent\Collection;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\App;
use Master\Modules\Websites\Facades\Websites;

/**
 * Aggiunge i blocchi di contenuto (sistema `Contents`) a un model che NON può
 * estendere Master\Modules\Pages\Models\Page perché eredita già da un model
 * di un altro package (es. Products con laravel-master-ecommerce).
 *
 * Il model che usa questo trait DEVE dichiarare:
 *   protected string $contentClass = <Entity>Content::class;
 *   protected string $content_foreign_key = '<entity>_id';
 *
 * E chiamare saveContentBlocks() dentro il proprio saveData(), DOPO aver
 * salvato colonne/traduzioni/valori:
 *   public function saveData(): bool {
 *       parent::saveData();
 *       $this->saveContentBlocks();
 *       return true;
 *   }
 */
trait HasContentBlocks
{
    public function page_contents($language = null): HasMany
    {
        $language ??= App::getLocale();

        return $this->hasMany($this->contentClass, $this->content_foreign_key, 'id')
            ->where('lang', '=', $language);
    }

    public function getBlocksAttribute($language = null): Collection
    {
        $language ??= App::getLocale();

        return $this->contentClass::where($this->content_foreign_key, $this->id)
            ->where('lang', '=', $language)
            ->where('draft', 0)
            ->orderBy('sequence', 'asc')
            ->get();
    }

    /** Hook per campi extra oltre a text/option — sovrascrivi se serve. */
    public function getCustomData($arr_data, $lang, $i): array
    {
        return $arr_data;
    }

    /**
     * Porzione di persistenza dei blocchi — replica ciò che
     * Page::saveData() fa per i moduli che estendono Page. Chiamalo
     * esplicitamente dal saveData() del tuo model (vedi PHPDoc sopra).
     */
    public function saveContentBlocks(): void
    {
        foreach (Websites::current('frontLanguages') as $lang) {
            $arr_contents = [];

            $contentId = request()->input('contentId__' . $lang['iso_code2']);
            $contentSequence = request()->input('contentSequence__' . $lang['iso_code2']);
            $contentType = request()->input('contentType__' . $lang['iso_code2']);
            $contentText = request()->input('contentText__' . $lang['iso_code2']);
            $contentOption = request()->input('contentOption__' . $lang['iso_code2']);

            if (is_array($contentId)) {
                for ($i = 1; $i <= request()->input('totalContents__' . $lang['iso_code2']); $i++) {
                    if (array_key_exists($i, $contentId)) {
                        $content = $contentId[$i]
                            ? (new $this->contentClass)->find($contentId[$i])
                            : new $this->contentClass();

                        $arr_data = $content->data;
                        $arr_data['text'] = $contentText[$i] ?? null;
                        $arr_data['option'] = $contentOption[$i] ?? null;
                        $arr_data = $this->getCustomData($arr_data, $lang, $i);

                        $content->{$this->content_foreign_key} = $this->id;
                        $content->lang = $lang['iso_code2'];
                        $content->type = $contentType[$i];
                        $content->sequence = $contentSequence[$i];
                        $content->draft = 0;
                        $content->data = $arr_data;
                        $content->save();

                        $arr_contents[] = $content->id;
                    }
                }
            }

            $contents = $this->page_contents($lang['iso_code2'])->where('draft', 0)->get();
            foreach ($contents as $content) {
                if (!in_array($content->id, $arr_contents)) {
                    $content->forceDelete();
                }
            }
        }
    }
}
```

Nota che qui `page_contents()`/`getBlocksAttribute()` sono **già generici** (usano `$this->contentClass`/`$this->content_foreign_key` dinamicamente) — a differenza delle versioni copiate a mano in Blog/Projects (Percorso A), che hardcodano il nome della classe nel corpo del metodo perché quello è ciò che serve per sovrascrivere correttamente il metodo hardcoded del genitore `Page`. Nel trait non c'è questo vincolo, quindi è scritto nel modo pulito fin da subito.

### 3B.2 Usa il trait sul model

```php
<?php

namespace Master\Modules\Products\Models;

use Enesisrl\LaravelMasterEcommerce\Modules\Products\Models\Product as Model;
use Master\Foundation\Modules\Base\Traits\HasContentBlocks;

class Product extends Model
{
    use HasContentBlocks; // ... più eventuali altri trait già in uso (Searchable, InteractsWithMedia, ...)

    protected string $contentClass = ProductContent::class;
    protected string $content_foreign_key = 'product_id';

    public function saveData(): bool
    {
        parent::saveData();       // colonne/traduzioni/valori — logica ecommerce esistente
        $this->saveContentBlocks(); // dal trait — i blocchi
        return true;
    }

    // ... resto del model, inalterato ...
}
```

**Un solo punto di attenzione**: se `saveData()` esiste già sul model (quasi certo, per un model ecommerce con logica propria di salvataggio), **non sovrascriverlo da zero** — aggiungi `$this->saveContentBlocks();` dentro l'implementazione esistente, dopo la parte che salva le colonne. Se invece `saveData()` non è definito e sale dritto dal package fino a `Model::saveData()`, la versione mostrata sopra (che chiama `parent::saveData()` poi il trait) è corretta com'è.

---

## 4. `config.php` — campo + tab

Identico in entrambi i percorsi:

```php
$form->addField('Contents', [
    'name'           => 'contents',
    'moduleName'     => 'ProductsModule',              // ⚠️ deve combaciare col case aggiunto al passo 5
    'contentConfigs' => ProductContent::getContentConfigs(),
]);

$form->addTab([
    'label'   => __('admin::label.contents'),
    'content' => [
        ['contents|col:12'],
    ],
]);
```

`moduleName` è una stringa libera — l'unica regola è che deve essere **esattamente** quella che scrivi nel `case` del passo 5. Convenzione osservata nel progetto: `"<Modulo>Module"` (`BlogModule`, `ProjectsModule`) — segui la stessa per consistenza, non perché sia richiesto dal codice.

---

## 5. IL PASSO CHE (QUASI) TUTTI SI SCORDANO — `newContent()`

Identico in entrambi i percorsi — questo passo non dipende da come hai risolto il model principale, solo da `moduleName`. Apri `Master\Modules\Services\Controllers\AdminController` (`master/Modules/Services/Controllers/AdminController.php`) e aggiungi un `case` allo switch dentro `newContent()`:

```php
public function newContent($page_id, $type, $data = [])
{
    switch (request()->input("moduleName")) {
        case "BlogModule":
            // ... esistente ...
        case "ProjectsModule":
            // ... esistente ...
        case "ProductsModule":                                       // ← AGGIUNGI QUESTO
            if (class_exists("\Master\Modules\Products\Models\ProductContent")) {
                return \Master\Modules\Products\Models\ProductContent::create([
                    "draft" => 1,
                    "product_id" => $page_id,
                    "type" => $type,
                    "data" => $data,
                ]);
            }
            break;
        default:
            // ... fallback PageContent, NON toccare ...
    }

    return null;
}
```

**Perché è critico e non "opzionale finché non serve":**

- Questa funzione serve **sia** al percorso standard (title/text/article/gallery/attachments/video_embed, via `parent::addContent()`) **sia** al percorso custom (`image_full`, gestito direttamente nello stesso controller). Non c'è modo di aggiungere blocchi al nuovo modulo — di NESSUN tipo — senza questo case.
- **Il fallimento è silenzioso.** Se lo salti, ogni click su "Aggiungi blocco" nel tab Contenuti di Products cade nel `default`: crea una riga in `page_contents` con `page_id` = l'id del tuo `Product` (che quasi certamente non esiste come pagina). L'admin non vede errori — vede semplicemente che il blocco non compare mai dopo il refresh, perché la lettura (`page_contents()` del passo 3) guarda `product_contents`, non `page_contents`. Il debug di questo sintomo senza sapere di questo passo è lento: sembra un problema di frontend/render, non di dispatch.
- Non esiste un modo config-driven per evitarlo (nessun binding automatico moduleName→classe): è un edit manuale di un file condiviso da tutti i moduli. Fallo con attenzione — non toccare gli altri `case`.

---

## 6. Tipi custom (es. `image_full`)

Nessuna azione aggiuntiva. `image_full` (e qualunque altro tipo custom già registrato via `getCustomContents()` — vedi `conventional-blocks.md`) è cablato nella **toolbar condivisa** (`Foundation/Modules/Crud/Views/contents/toolbar.blade.php`, app-level, usata da TUTTI i moduli) e nel **field Contents** condiviso (`Master\Foundation\Form\Fields\Contents::getCustomContents()`). Una volta fatto il passo 5, `image_full` funziona automaticamente anche su Products — perché passa dallo stesso `newContent()` che hai appena estenso, indipendentemente dal percorso A o B usato al passo 3.

Se invece vuoi un tipo custom **esclusivo** di Products (non condiviso con Pages/Blog/Projects), quello richiede lavoro aggiuntivo — vedi "Aggiungere un tipo di blocco nuovo" in `conventional-blocks.md`.

---

## 7. Verifica end-to-end

1. `php artisan migrate` (da `private/`).
2. Apri il form di un Product esistente → tab Contenuti → "Aggiungi blocco" → Testo. Se non appare nulla o appare un errore JS silente in console, sei quasi certamente al passo 5.
3. Scrivi qualcosa, salva il form. Controlla `product_contents` in DB (non `page_contents`) — deve esserci la riga con `product_id` corretto e `draft=0`.
4. Ricarica il form: il blocco deve rileggersi (verifica passo 3, `page_contents()`).
5. Sul frontend, chiama `$product->blocks` (o passa `$product` a un `<x-block-renderer>` se lo riusi) — deve restituire la collection dalla tabella giusta (verifica `getBlocksAttribute()`).
6. Elimina il blocco dall'admin e salva di nuovo → la riga deve sparire da `product_contents` (verifica il cleanup, che dipende dal passo 3 — `saveContentBlocks()` nel Percorso B).

Se un solo passaggio di questa lista fallisce, torna al numero corrispondente — non improvvisare un fix nel frontend per un problema che è nel dispatch o nella relazione.
