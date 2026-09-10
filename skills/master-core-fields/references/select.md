# Field: Select

Dropdown `<select>`. Classe: `Foundation/Form/Fields/Select.php`. Le opzioni non sono statiche nel `config.php`: vengono generate in `getOptions()` in base a `type`.

## I 4 `type` e da dove arrivano le opzioni

| `type` | Da dove legge le opzioni | Config richiesta |
|---|---|---|
| `standard` | Query SQL raw eseguita al render | `query` — SQL che DEVE restituire colonne `value` e `description` |
| `values` | Array PHP passato direttamente | `resultSet` — array di `['value'=>..., 'description'=>...]` (o oggetti con quelle proprietà) |
| `enum` | `SHOW COLUMNS FROM <table> LIKE '<field>'` — legge i valori dell'enum/set MySQL della colonna | `table` (+ `field_name` se il nome colonna differisce da `name`) |
| `ajax` | Nessuna query lato server: il markup produce solo `<input type="hidden">` col valore corrente; le opzioni le carica il JS via AJAX | `ajaxCallClass` |

Esempi reali (`Modules/Websites/config.php`, `Modules/Categories/config.php`, `Modules/Languages/config.php`):

```php
// standard — query diretta
$form->addField('Select', [
    'name'  => 'lang_front_default',
    'type'  => 'standard',
    'query' => "SELECT languages.id value, languages.description FROM languages WHERE languages.type='front' ORDER BY languages.description",
    'label' => __('admin::label.lang_front_default'),
]);

// values — resultSet costruito in PHP (spesso da un helper statico del modulo referenziato)
$form->addField('Select', [
    'name'      => 'website_id',
    'type'      => 'values',
    'resultSet' => Websites::getWebsitesForSelect(),
    'label'     => __('admin::label.gestore'),
    'rules'     => ['required'],
]);

// enum — legge i valori enum della colonna 'area' nella tabella 'categories'
$form->addField('Select', [
    'name'  => 'area',
    'type'  => 'enum',
    'table' => 'categories',
    'label' => __('admin::label.area'),
]);
```

> Nel `type=values`, se un elemento di `resultSet` non ha `description`, il field prova `__("admin::option.".$value)` come fallback — quindi puoi passare solo `value` se esiste già quella chiave di traduzione.

> Nel `type=enum` le description usano `admin::option.<valore_lowercase>` se la chiave esiste, altrimenti `strtoupper($opt)` grezzo — conviene sempre censire le chiavi `admin::option.*` per i valori enum.

## Multiplo (`multiple`)

```php
'multiple' => true,
'multiple-options' => '...', // opzionale, passato come attributo data-admin-multiselect="..."
```

Con `multiple => true`:
- l'attributo `name` diventa `nome[]` (array), NON `nome`;
- se il campo NON è nel `protected $related` del model, `saveData()` ignora i valori — vedi §2/§6 del `SKILL.md` principale (comportamento "multi-valore" → tabella `<entity>_values`);
- il valore letto da `getValue()` può essere sia un array scalare sia una `Collection` (Eloquent relation) — il field gestisce entrambi i casi convertendo la Collection in array di `id`.

## `readonly` vs `disabled` — comportamenti diversi

Non sono equivalenti:

- **`readonly: true`** → il field chiama `renderReadonlySelect()`: niente `<select>`, solo un `<input readonly>` col testo della description selezionata + un hidden col value reale. Il valore **arriva comunque in Request** (viene comunque salvato).
- **`disabled: true`** → il `<select>` viene renderizzato con l'attributo HTML `disabled` (che i browser NON inviano in Request) più un `<input type="hidden">` di supporto con lo stesso valore, così il salvataggio funziona comunque. Il `name` interno usa il suffisso `_disabled` per evitare collisioni fra i due input.

## `select2`

`'select2' => true` aggiunge l'attributo `data-admin-select2`, che attiva il plugin Select2 lato JS (ricerca/autocomplete nel dropdown). Utile quando il `resultSet`/query produce molte opzioni.

## viewMode

In `viewMode` (form in sola lettura), `getValue()` non ritorna il value grezzo ma la/le `description` corrispondenti (join con `<br />` se multiplo) — quindi in view mode vedi il testo leggibile, non l'id/value tecnico.

## Errori comuni

- Dimenticare `value`/`description` come alias di colonna nella query `standard` → il render fallisce silenziosamente (opzioni vuote) perché il field cerca esattamente `$row->value` e `$row->description`.
- Usare `multiple => true` senza aggiungere il nome del campo a `protected $related` nel model → i valori si perdono al salvataggio anche se il form li mostra correttamente in edit (finché non si ricarica).
- Con `type=enum`, dimenticare `field_name` quando il nome del campo Form non coincide col nome reale della colonna DB.
