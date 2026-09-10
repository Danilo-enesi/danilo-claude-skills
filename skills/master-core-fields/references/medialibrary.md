# Field: MediaLibrary

Upload/gestione file basato su **Spatie MediaLibrary**. Classe: `Foundation/Form/Fields/MediaLibrary.php`. Il `name` del campo = nome della **collection** Spatie su quel model (`$this->model->getMedia($name)`), NON una colonna.

## Config

```php
$form->addField('MediaLibrary', [
    'name'              => 'cover',                       // = nome della media collection
    'maxNumberOfFiles'  => 1,                              // default 1; >1 abilita ordinamento drag & delete-all
    'allowedFileTypes'  => ['jpg', 'jpeg', 'png', 'gif'],  // estensioni ammesse (client-side)
    'allowedFileTypesField' => null,                       // opz.: nome campo che determina i tipi ammessi dinamicamente
    'maxFileSize'       => 15728640,                        // opz., default ~15MB (byte)
    'disableEditImage'  => true,                            // nasconde il bottone "modifica" (crop/edit) sull'immagine
    'label'             => __('admin::label.cover_image'),
    'help'              => __('admin::help.eventnews_cover_image'),
]);
```

Esempi reali (`Modules/Events/config.php`, `Modules/Counters/config.php`, `Modules/Websites/config.php`):

```php
// singolo file, immagine di copertina
$form->addField('MediaLibrary', [
    'name' => 'cover', 'maxNumberOfFiles' => 1, 'disableEditImage' => true,
    'allowedFileTypes' => ['jpg', 'jpeg', 'png', 'gif'],
    'label' => __('admin::label.cover'), 'help' => __("admin::help.eventnews_cover_image"),
]);

// collezione multi-file (galleria)
$form->addField('MediaLibrary', [
    'name' => 'image', 'maxNumberOfFiles' => 100,
    'allowedFileTypes' => ['jpg', 'jpeg'],
    'label' => __('admin::label.images'), 'help' => __('admin::help.image_format_sizes'),
]);
```

## Requisito: la collection deve esistere sul model

Il field legge `$this->model->getMedia($this->config['name'])` — se il model non conosce quella collection il file caricato finisce comunque nella media library generica ma **le conversioni (thumbnail) non vengono generate** a meno che tu registri esplicitamente:

```php
public function registerMediaCollections(): void
{
    $this->addMediaCollection('cover')->singleFile();   // singleFile() se maxNumberOfFiles = 1
    $this->addMediaCollection('image');                  // senza singleFile() per collezioni multiple
}

public function registerMediaConversions(?Media $media = null): void
{
    $this->addMediaConversion('thumb')
        ->performOnCollections('cover')
        ->fit(Fit::Crop, 827, 827)
        ->nonOptimized()   // per hosting condivisi senza estensioni immagine avanzate
        ->nonQueued();     // idem: genera la conversione in modo sincrono
}
```

> **Regola pratica**: `maxNumberOfFiles => 1` nel `config.php` e `->singleFile()` in `registerMediaCollections()` vanno **sempre insieme** — se non coincidono ottieni comportamenti inconsistenti (il field mostra 1 slot ma Spatie ne accetta N o viceversa).

## Comportamenti da tenere a mente

1. **Richiede un `id` esistente** — in creazione (`$this->model->id` nullo) il bottone upload appare `disabled` e viene mostrato il messaggio *"carica disponibile solo in modifica"* (`admin::message.upload_media_only_on_update`). Metti questo campo in un tab visibile solo dopo il primo salvataggio, o accetta che in creazione sia inattivo.
2. **`maxNumberOfFiles` è un tetto cumulativo**, non per-upload: il field calcola `maxNumberOfFiles - count(media_esistenti)` per limitare quanti file si possono ancora aggiungere.
3. **Ordinamento drag** (`data-action="order"`) appare solo se `maxNumberOfFiles > 1` — non ha senso per singolo file.
4. **`disableEditImage`** nasconde solo il bottone "modifica/crop" per le immagini; non blocca upload/delete.
5. **Tipi non-immagine** (pdf, doc, csv, zip, mp4...) mostrano un'icona statica per mime-type invece della preview; l'elenco dei mime riconosciuti è hardcoded nel field — un mime non previsto usa l'icona generica "file".
6. **`renderViewMode()` chiama `render()`**: in sola lettura vedi comunque le anteprime/file, ma senza bottoni upload/delete/order (perché quei blocchi controllano `!$this->viewMode`).
7. Il valore non passa mai da `getRequestValue()`/`fillModel()` standard: l'upload/delete/ordinamento sono azioni AJAX separate gestite dal JS (`data-admin-media-library-input`), non dal submit del form.

## Checklist per usarlo

1. Il model ha (o eredita) il trait/interfaccia Spatie `HasMedia`?
2. Serve `registerMediaCollections()` con lo stesso nome di `name` e coerente `singleFile()`/non-singleFile con `maxNumberOfFiles`?
3. Servono conversioni (`registerMediaConversions()`) per generare thumbnail coerenti col frontend?
4. `addField('MediaLibrary', ['name'=>..., 'maxNumberOfFiles'=>..., 'allowedFileTypes'=>[...], 'label'=>...])`.
5. Se il modulo è nuovo/in creazione, verifica che il campo sia in un tab raggiungibile anche prima del primo salvataggio (per non nasconderlo del tutto).
