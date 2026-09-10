# Field: Crud

Non è un input: renderizza una **tabella CRUD di un altro modulo, filtrata sul record padre corrente** (relazione "1 a molti" gestita inline dentro il form). Classe: `Foundation/Form/Fields/Crud.php`.

## Config

```php
$form->addField('Crud', [
    'name'          => 'user_websites',   // solo identificativo interno, non è una colonna
    'module'        => 'UserWebsites',    // nome del modulo figlio (senza suffisso "Module")
    'reference_key' => 'user_id',         // FK nel modulo figlio che punta al record padre
]);

$form->addTab([
    'label'   => __('admin::label.informazioni_generali'),
    'content' => [
        ['user_websites'],   // referenzialo in un tab come qualsiasi altro campo
    ],
]);
```

Esempi reali: `Modules/Users/config.php` (`user_websites` → modulo `UserWebsites`), `Modules/Dropdowns/config.php` (`dropdown_childs` → modulo `DropdownChilds`), `Modules/Products/config.php` (`product_pricelists` → modulo `ProductPricelists`).

## Cosa fa `render()` internamente

1. Risolve il modulo figlio via `App::make($this->config('module') . 'Module')` (facade/service container, stesso pattern di `Foundation` — il modulo figlio deve esistere ed essere registrato in `config/master.php`).
2. Se il record padre **non è ancora salvato** (niente `id`), mostra il messaggio *"Completa il salvataggio per accedere a questi contenuti."* invece della tabella — non esiste ancora un valore per `reference_key`.
3. Se l'utente ha il permesso `create` sul modulo figlio (`$submodule->can('create')`) e il form padre non è in `viewMode`, mostra un bottone "crea" che apre l'AJAX modal del modulo figlio, precompilando `parent: {reference_key: model->id}`.
4. Costruisce le colonne della tabella (`<thead>`) leggendo `$submodule->getListStructure()` — cioè **la stessa lista/colonne configurate nel `config.php` del modulo figlio** (`crud.list`), non una lista separata da definire qui.
5. Renderizza una `<table data-admin-datatable='...'>` che il JS del tema inizializza come DataTable AJAX, con `preset: "crud"` e il filtro `parent` sempre applicato lato server.

## Conseguenza pratica

- **Il campo Crud non definisce colonne/comportamento proprio**: tutto (colonne, permessi, azioni riga) viene dal `config.php` del **modulo figlio** referenziato in `module`. Per cambiare cosa si vede in questa tabella, modifica il modulo figlio, non il campo.
- **`reference_key` deve esistere davvero** come colonna FK nel modulo figlio (fillable, migration) — è il valore che viene forzato nella richiesta di creazione/lista (`parent: {reference_key: id}`).
- Funziona **solo dopo il primo salvataggio** del record padre (serve un `id` reale) — in creazione va quindi tipicamente isolato in un tab separato o mostrato dopo il primo save, come gli altri campi che dipendono da `id` (`MediaLibrary`).
- `renderViewMode()` richiama semplicemente `render()`: la tabella resta visibile (senza bottone "crea") anche in sola lettura.

## Checklist per usarlo

1. Il modulo figlio esiste ed è registrato (`config/master.php`)? Ha già un `config.php` con `crud.list` definito?
2. Il modulo figlio ha una colonna FK verso il padre (es. `user_id`, `dropdown_id`) inclusa nel `$fillable`?
3. `addField('Crud', ['name'=>..., 'module'=>'<ModuloFiglio>', 'reference_key'=>'<fk_colonna>'])`.
4. Referenzia il campo in un `addTab` — di solito da solo in un tab dedicato (es. `['label' => ..., 'content' => [['user_websites']]]`).
5. Non serve validazione (`rules`) né gestione salvataggio: il campo non scrive nulla sul model padre, è solo una vista embedded.
