# Blocchi convenzionali — catalogo, come estenderli, come aggiungerne uno nuovo

> Presuppone `references/package-internals.md` (specialmente Capa 2 e 3). Qui si lavora sempre nella cartella `Master\Foundation\Form\Contents\` (editor widget admin) — NON nella cartella dei componenti frontend (`Front\Main\Components\Blocks\`, vedi `frontend-convention.md`).

## Catalogo dei 6 tipi standard + 1 custom

I 6 standard sono **fissi nel package** (mappa hardcoded in `createContentInstance()`, package-internals.md Capa 3) — non ne puoi aggiungere un 7° a questa lista, solo estendere questi o passare dal meccanismo custom.

| `type` DB | Classe editor widget | Chiavi `data` | Media collection | Richiede `media_id`? |
|---|---|---|---|---|
| `title` | `Contents\Title` | `text` | — | no |
| `text` | `Contents\Text` | `text`, `option`/`style`, + extra custom (vedi sotto) | — | no |
| `article` | `Contents\Article` | `text`, `option`, `media_id` | `contentArticle__<media_id>` | sì |
| `gallery` | `Contents\Gallery` | `media_id` | `contentGallery__<media_id>` | sì |
| `attachments` | `Contents\Attachment` | `text`, `body`, `media_id` | `contentAttachment__<media_id>` | sì |
| `video_embed` | `Contents\VideoEmbed` | `text`, `caption` | — | no |
| `image_full` *(custom)* | `Contents\ImageFull` | `text`, `option`, `media_id` | `contentImageFull__<media_id>` | sì |

`requiresMediaId($type)` (core, Capa 3) elenca esplicitamente `['gallery', 'attachments', 'article']` — se aggiungi un tipo custom con media, il tuo dispatch (vedi §"Aggiungere un tipo nuovo") deve gestire l'assegnazione di `media_id` da solo, come fa già `image_full` in `Services\AdminController::addContent()`.

**`option`/`style` — value set condiviso**, in `config/master.php` (`contentConfigs`):
- `article`: layout immagine (`left-pic-right-text`, `right-pic-left-text`, `top-pic-bottom-text`, `bottom-pic-top-text`)
- `text`: stile (`standard`, `citazione`)
- `image_full`: parallax (`si`, `no`)

---

## Anatomia di una classe editor widget

Tutte estendono `Master\Foundation\Form\Content` (a sua volta `Enesisrl\LaravelMasterCore\Foundation\Form\Content` — vedi package-internals.md Capa 2 per le property disponibili: `$this->model`, `$this->lang`, `$this->cont`, `$this->config(...)`, `$this->getValue(...)`).

```php
class Text extends \Enesisrl\LaravelMasterCore\Foundation\Form\Contents\Text
{
    public function register(): void
    {
        parent::register(); // costruisce $this->form + il campo testo base

        // aggiungi sotto-campi: SEMPRE con name univoco per indice/lingua
        $this->form->addField('Select', [
            'name'         => 'contentTextStyle__' . $this->lang . '[' . $this->cont . ']',
            'type'         => 'values',
            'label'        => __('admin::label.stile'),
            'sessionValue' => $this->getValue('style'),   // rilegge il valore salvato in data['style']
            'resultSet'    => $this->contentConfigs['contentTextStyleOptions'],
        ]);
    }

    public function render(): string
    {
        // ... compone $content_card_body con $this->form->renderContent([...]) ...
        return view($this->moduleName . '::contents.base.content', [
            'content_card_body'  => $content_card_body,
            'lang'               => $this->lang,
            'content'            => $this->model,
            'cont'               => $this->cont,
            'moduleName'         => $this->moduleName,
            'viewMode'           => $this->viewMode,
            'content_card_title' => __('admin::contents.text'),
        ])->render();
    }
}
```

**Regole non negoziabili sui `name` dei sotto-campi:**
- Pattern fisso: `content<Chiave>__<lang>[<cont>]` — es. `contentTextStyle__it[3]`. `<Chiave>` è quella che poi leggerai in `getCustomData($arr_data, $lang, $i)` sul model principale (`request()->input("content<Chiave>__" . $lang["iso_code2"])`).
- `<cont>` è l'indice posizionale del blocco nel tab (assegnato da `Contents::render()`), NON l'id del content-model.
- Se il `name` non segue questo pattern, il campo si vede e si compila in admin ma **`saveData()` non lo legge mai** — bug silente identico a quello del dispatch (package-internals.md).

---

## Estendere un tipo esistente (caso reale: `Text` con stile/layout/colore)

Il progetto ha già un esempio reale di estensione sicura di un tipo standard: `Text` guadagna 4 sotto-campi extra (stile citazione, layout, colore testo, colore sfondo) senza toccare il package.

**Procedura generale:**
1. **Estendi la classe app-level esistente** (`Master\Foundation\Form\Contents\Text extends Enesisrl\LaravelMasterCore\Foundation\Form\Contents\Text`) — non quella vendor.
2. In `register()`, chiama `parent::register()` PRIMA, poi aggiungi i tuoi campi extra al `$this->form` interno.
3. In `render()`, ricostruisci il layout completo (stile+testo+condizionali) — non puoi "inserire in mezzo" ai campi del padre in modo pulito, quindi la maggior parte delle estensioni reali sovrascrive `render()` per intero, riusando `$this->form->renderContent([...])` con le righe nell'ordine voluto.
4. Le nuove chiavi (`style`, `layout`, `color`, `bg_color`) le persisti aggiungendo i rami corrispondenti in `getCustomData()` sul model principale (`Page::getCustomData()`), che `saveData()` (Capa 4) chiama per ogni blocco.
5. Se un sotto-campo deve mostrarsi/nascondersi in base a un altro (es. layout+colori visibili solo per `style === 'citazione'`), il toggle **iniziale** (primo render server-side) va calcolato in PHP (`$isCitazione = $this->getValue('style') === 'citazione'`); il toggle **live** (cambio a runtime senza reload) è JS puro (`custom.js`/plugin `Admin`, MAI dentro `render()` — vedi la skill `master-core-fields` §7bis per le regole JS/CSS nei Field).

**Regola di sicurezza (stessa della skill `master-core-fields` §7):** se il tipo è condiviso da più moduli (es. `text` lo usano Pages/Blog/Projects), i campi extra devono essere **retro-compatibili**: opzionali, con default che preservano il comportamento attuale per i blocchi già salvati senza quelle chiavi (`$arr_data['layout'] ?? 'standard'`, non un default che cambia il rendering esistente).

---

## Aggiungere un tipo di blocco NUOVO end-to-end

I 6 tipi standard sono chiusi (mappa fissa in `createContentInstance()`, package vendor — non toccare `vendor/`). **Un tipo nuovo è SEMPRE un tipo custom**, esattamente come `image_full`. Segui questo template usando `image_full` come riferimento reale funzionante.

1. **Editor widget class** — `Master\Foundation\Form\Contents\<Nome>` estende direttamente `Master\Foundation\Form\Content` (non un tipo standard, a meno che il nuovo tipo non sia davvero una variante di uno esistente). Implementa `register()`/`render()` come sopra.

2. **Toolbar** — aggiungi la voce in `master/Foundation/Modules/Crud/Views/contents/toolbar.blade.php` (app-level, **condivisa da tutti i moduli** — quindi il tipo nuovo diventa disponibile ovunque il field `Contents` è montato, non solo nel modulo dove ne avevi bisogno):
   ```blade
   <a class="dropdown-item" data-admin-add-content='{"type":"<nuovo_type>","lang":"{{ $lang }}","viewsModuleName":"{{ $viewsModuleName }}","moduleName":"{{ $moduleName }}","model_id":"{{ $model_id }}"}' href="#">{{ __('admin::contents.<nuovo_type>') }}</a>
   ```
   Aggiungi anche la label in `resources/lang/admin/it/contents.php` (o l'override app-level).

3. **Hook custom nel Field** — `Master\Foundation\Form\Fields\Contents::getCustomContents()`:
   ```php
   public function getCustomContents($viewsModuleName, $lang, $cont, $content, $contentConfigs = null)
   {
       if ($content->type === '<nuovo_type>') {
           return new \Master\Foundation\Form\Contents\<Nome>($viewsModuleName, $lang['iso_code2'], $cont, $content, $contentConfigs);
       }
       // ... rami esistenti (image_full) ...
       return null;
   }
   ```

4. **Dispatch AJAX** — in `Services\AdminController::addContent()`, aggiungi `'<nuovo_type>'` a `$customTypes`, e nel `switch` che segue aggiungi il ramo che istanzia la tua classe (identico al ramo `image_full`). Se il tipo richiede media, replica `$content->addData("media_id", Tool::newHashId())` prima di `$content->saveData()`.

5. **Persistenza extra** — se il tipo ha campi oltre `text`/`option`, estendi `getCustomData()` sul/sui model principali che lo useranno (come per l'estensione di `Text`).

6. **Frontend** — vedi `references/frontend-convention.md` per la parte pubblica (componente Blade + classe CSS dedicata).

7. **Traduzioni label admin** se servono, via skill `master-ln-upd`.

> Questo è più lavoro che estendere un tipo esistente (§ precedente) — prima di percorrerlo, verifica seriamente se il "nuovo" tipo non sia in realtà una variante di `text`/`article`/`image_full` gestibile con un `option` in più (vedi la regola anti-duplicazione della skill `master-core-fields` §7: non reinventare se basta una variante retro-compatibile).

---

## Errori da evitare

- ❌ Aggiungere una voce toolbar senza il ramo corrispondente in `getCustomContents()` **e** in `addContent()`/`$customTypes` — la voce appare ma il click non fa nulla (o crea un content dal `type` sbagliato).
- ❌ Un `name` di sotto-campo che non segue `content<Chiave>__<lang>[<cont>]` — si vede in admin, non salva mai.
- ❌ Assumere che i 6 tipi standard siano estensibili in numero — sono un array fisso in `createContentInstance()` (vendor). Un 7° tipo è sempre "custom".
- ❌ Modificare `vendor/enesisrl/laravel-master-core` direttamente — ogni fix va nel repo `laravel-master-dev` e tirato via Composer; a livello progetto usa sempre gli override in `Master\Foundation\Form\Contents\*` / `Master\Foundation\Form\Fields\Contents`.
- ❌ Rompere la retro-compatibilità di un tipo condiviso (Testo/Article/...) aggiungendo un campo extra senza default sicuro — i blocchi già salvati su altri moduli non hanno quella chiave in `data`.
