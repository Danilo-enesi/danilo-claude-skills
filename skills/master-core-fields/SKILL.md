---
name: master-core-fields
description: Come creare, valorizzare e personalizzare i CAMPI (Field) dei form admin del Master Laravel Enesi (laravel-master-core). Attivala quando aggiungi o modifichi un campo in un `config.php` di modulo (`$form->addField(...)`): scegliere il tipo giusto, capire dove finisce il valore (colonna / traduzione / tabella valori / media / indirizzo), impostare validazioni/regole, o creare un Field custom estendendo la classe base. Frasi tipiche: «aggiungi un campo», «nuovo field / addField», «campo del form», «validazione campo», «campo multilingua», «campo select/checkbox/media/data», «field custom», «personalizzare un campo».
---

# Skill: Creare campi (Field) di master-core

> **Regola d'oro**: un campo NON è HTML statico. È una classe PHP registrata via `$form->addField('<Tipo>', [config])` in `config.php`. Il **nome** del campo decide **dove** viene salvato il valore. Il **tipo** decide come si renderizza, valida e riempie il model. Non scrivere mai `<input>` a mano in una view admin: aggiungi un Field.

## Validazione — scripts dedicati (`scripts/`), non a memoria

Questa skill ha due parti distinte: una **guida concettuale** (come funziona il sistema dei Field — sotto) e una **validazione meccanica** fatta da script deterministici, non da giudizio dell'AI. La sintassi obbligatoria di un Field custom (estende la base giusta, ha `render()`, namespace coerente con la posizione, nome classe = nome file) e la regola "0 JS/CSS inline" **non si controllano leggendo il codice a occhio**: le verifica uno script, sola lettura, richiamabile da CLI.

| Script | Cosa verifica |
|---|---|
| `scripts/check-field-class-structure.php <path>` | Un Field custom estende `Field`/`BaseField`; dichiara `render()`; il namespace combacia con la cartella (`Foundation/Form/Fields` → `Master\Foundation\Form\Fields`, `Modules/<Nome>/Form/Fields` → `Master\Modules\<Nome>\Form\Fields`); il nome della classe combacia col nome del file |
| `scripts/check-field-no-inline-assets.php <path>` | Nessun `<script>`, `<style>`, `onclick=`, `style=` dentro un Field custom (§7bis) |

Uso: `php scripts/<nome>.php <path-file-o-cartella>`. Output JSON su stdout: `{ script, target, files_checked, findings: [{rule, severity, file, line, message, confidence?}] }`. Come negli script di `master-code-review`: euristiche a regex, non un parser PHP/AST — su casi ambigui emettono `confidence: "da_verificare"` invece di affermare un errore.

**Quando eseguirli**: sempre dopo aver creato o modificato un Field custom (§7), prima di considerarlo finito. Esegui entrambi gli script sulla cartella `Form/Fields/` interessata, traduci ogni riga di `findings` in un problema da correggere — non ri-derivare a mano ciò che lo script ha già stabilito.

> Nota: `master-code-review` ha script propri che si sovrappongono parzialmente a questi (`check-field-antipatterns.php` copre anche JS/CSS inline nei Field custom, `check-field-destinations.php` copre il mapping name→destinazione). La deduplicazione fra le due skill è una decisione ancora da prendere — per ora entrambi gli insiemi di script sono validi e indipendenti.

## Il catalogo dei tipi (§5) può essere obsoleto — verifica sempre sulla fonte

La tabella dei tipi in §5 è una **guida**, non la fonte di verità: nuovi tipi possono essere aggiunti al package o a `Master\Foundation\Form\Fields` senza che questo file venga aggiornato. Se stai per usare un tipo che non ricordi con certezza, o vuoi essere sicuro dell'elenco completo e aggiornato, **non fidarti della tabella a memoria**: elenca dal vivo `private/vendor/enesisrl/laravel-master-core/src/Foundation/Form/Fields/*.php` (+ eventuali override in `private/master/Foundation/Form/Fields/*.php`) e leggi la classe stessa per la config supportata. La tabella serve per orientarsi velocemente, la lettura del sorgente è quella che decide.

## 0. Prima di iniziare: dove vivono i campi

- I campi si dichiarano nel **`config.php`** del modulo: `private/master/Modules/<Nome>/config.php`, dentro `crud.form = function($form, $model){ ... }`.
- Le **classi base** dei tipi stanno nel package (NON modificarle):
  `private/vendor/enesisrl/laravel-master-core/src/Foundation/Form/Fields/*.php`
  e la classe astratta `Foundation/Form/Field.php` + l'orchestratore `Foundation/Form/Form.php`.
- I campi custom si possono definire a **due livelli** (vedi §7):
  - **Globale di progetto**: `private/master/Foundation/Form/Fields/` (namespace `Master\Foundation\Form\Fields`) — risolto per nome breve.
  - **Locale al modulo**: `private/master/Modules/<ModuleName>/Form/Fields/<FieldName>.php` (namespace `Master\Modules\<ModuleName>\Form\Fields`) — risolto passando l'FQCN.

`addField($class, $config)` risolve la classe così (`Form::addField`):
1. `\Master\Foundation\Form\Fields\{$class}` (nome breve → override/globale di progetto) — **ha priorità**;
2. altrimenti `{$class}` interpretato come **FQCN completo** (es. classe locale al modulo);
3. deve estendere `Field`, altrimenti `RuntimeException`.

Quindi:
- `'Varchar'` (stringa breve) → tipo del package, salvo che esista `Master\Foundation\Form\Fields\Varchar`.
- `Master\Modules\Roles\Form\Fields\Permissions::class` (FQCN) → campo definito **dentro il modulo**.

Esempio reale — `Modules/Roles/config.php`:
```php
use Master\Modules\Roles\Form\Fields\Permissions as PermissionsField;
// ...
$form->addField(PermissionsField::class, [ 'name' => 'permissions', /* ... */ ]);
```
Con la classe in `private/master/Modules/Roles/Form/Fields/Permissions.php` e namespace `Master\Modules\Roles\Form\Fields`.

## 1. Modello mentale: il ciclo di vita di un Field

Ogni Field attraversa queste fasi (definite in `Field.php`, orchestrate da `Form.php`):

| Fase | Metodo | Cosa fa |
|---|---|---|
| Costruzione | `__construct` → `register()` | riceve la config; `register()` (override) può costruire sotto-campi |
| Lettura valore | `getValue()` / `getValueLang($lang)` | legge dal model (colonna, traduzione, tabella valori, indirizzo) |
| Render form | `render()` | produce l'HTML dell'input |
| Render sola lettura | `renderViewMode()` | HTML in viewMode (default: label + valore) |
| Validazione | `modifyValidator()` → `getValidatorRules()` | applica `rules` al Validator |
| Salvataggio | `fillModel()` | scrive `getRequestValue()` sul model |

Il salvataggio finale su DB (traduzioni, tabella valori, indirizzi) NON lo fa il Field: lo fa il **model** in `saveData()` (base `Model.php`), leggendo la Request per nome campo. Il Field deve solo produrre un `name` HTML coerente con la convenzione (§2).

## 2. LA COSA PIÙ IMPORTANTE: il `name` decide dove va il valore

Il `name` del campo NON è arbitrario. È il contratto con `saveData()`:

| Se `name` = ... | Il valore finisce in ... | Condizione |
|---|---|---|
| `sequence`, `published`, `date_from` (colonna diretta) | colonna della tabella principale | il nome è nel `$fillable` del model |
| `description__it`, `meta_title__en` (auto-generato dai campi `*Lang`) | tabella `<entity>_translations` (colonna `description`, riga `lang=it`) | il nome base è nel `$fillable` del **Translation** model |
| `project_category_id` | tabella `<entity>_values` (`field_name`/`field_value`) | il nome è nell'array `protected $related` del model |
| `cover`, `image` | Spatie MediaLibrary (collection omonima) | esiste `registerMediaCollections()` con quella collection |
| `address_id` | tabella indirizzi | il model usa `HasAddresses` e lo dichiara in `initializeHasAddresses()` |

**Conseguenza pratica**: aggiungere un campo spesso richiede più del solo `addField`. Prima di dichiarare il campo, verifica che la destinazione esista:

- **Campo colonna diretta** → aggiungi la colonna nella migration e mettila nel `$fillable` del model.
- **Campo multilingua** (`*Lang`) → la colonna base deve esistere nella tabella `_translations` e nel `$fillable` del Translation model. NON serve la colonna `nome__it`: `saveData()` fa il match su `campo__lang`.
- **Campo multi-valore** (`Select multiple`, categorie…) → aggiungi il nome all'array `protected $related` del model; i valori vanno in `<entity>_values`.
- **Media** → aggiungi la collection in `registerMediaCollections()` (+ eventuali conversioni).
- **Indirizzo** → trait `HasAddresses` + `initializeHasAddresses()`.

> Se salvi un campo e "sparisce", quasi sempre è perché la destinazione non è dichiarata: non è nel `$fillable`, non è nel Translation `$fillable`, o manca da `$related`.

## 3. Anatomia di `addField` + chiavi di config comuni

```php
$form->addField('Varchar', [
    'name'             => 'phone',                       // OBBLIGATORIO — vedi §2
    'label'            => __('admin::label.phone'),      // etichetta (usa le lang key admin::)
    'rules'            => ['nullable', 'max:50'],         // regole Laravel Validator (array o closure)
    'help'             => __('admin::help.phone'),        // testo sotto l'input
    'placeholder'      => '+39 ...',
    'customCssClasses' => 'text-uppercase',               // classi extra sull'input
    'readonly'         => true,                            // solo lettura
    'disabled'         => true,                            // disabilitato (invia hidden col valore)
]);
```

Chiavi valide su (quasi) tutti i campi — lette via `$this->config(...)`:

- `name` (obbligatorio), `label`, `help`, `rules`, `placeholder`, `customCssClasses`.
- `maxlength` → attributo `data-admin-maxlength` + regola implicita in alcuni campi Lang.
- `readonly`, `disabled` (dove supportati).
- `field_name` → nome colonna DB reale se diverso da `name` (usato per `enum`, `Date`, list).
- `custom_value` → forza un valore fisso, scavalca il model.
- `sessionValue` → valore preso dalla sessione (es. filtri di ricerca).
- `displayValue` → valore mostrato in viewMode; può essere una **closure** `fn($value) => ...`.
- `lang_source` → `'admin'` usa le lingue admin, altrimenti le lingue front (per i campi multilingua).
- `viewMode` → forza la sola lettura.

**Layout**: dopo aver aggiunto i campi, li disponi in tab/righe con `addTab`, referenziando i campi per `name` con la sintassi `nome|col:6` (griglia Bootstrap a 12), più pseudo-elementi `:separator`, `:section-title|title:...`, `:section-subtitle|title:...`.

```php
$form->addTab([
    'label'   => __('admin::label.informazioni_generali'),
    'content' => [
        ['published|col:2', 'sequence|col:2', 'date_from|col:4', 'date_to|col:4'],
        [':separator'],
        ['description|col:12'],
    ],
]);
```

Un campo aggiunto con `addField` ma **non referenziato** in nessun tab non viene renderizzato (ma esiste comunque per validazione/salvataggio se presente nella Request).

## 4. `rules`: validazione

`rules` accetta:
- un **array** di regole Laravel: `['required', 'max:255', 'nullable', 'date', 'after_or_equal:date_from']`;
- una **closure** che riceve il model: `'rules' => fn($model) => $model->id ? ['nullable'] : ['required']`.

Le regole vengono unite nel Validator del form (`Form::getValidator`). I messaggi arrivano da `admin::validation`. La label del campo viene registrata come attributo custom, quindi i messaggi usano la label giusta.

Per i campi multilingua (`*Lang`) le regole `required`/`maxlength` vengono propagate a **ogni** sotto-campo lingua automaticamente (vedi `TextLang::register`).

## 5. Catalogo dei tipi disponibili (package)

Tipi in `Foundation/Form/Fields/`. Colonna "Salva dove" = comportamento tipico in base al `name` (§2).

> Per i tipi con comportamento complesso esiste un file satellite in `references/` con dettagli, esempi reali dai moduli e insidie note (caricato solo quando serve, non ingombra questo file): `select.md`, `crud.md`, `medialibrary.md`.

### Testo / input semplici
| Tipo | Uso | Config specifica |
|---|---|---|
| `Varchar` | input testo `<input type=text>` | `numbersonly`, `readonly`, `disable_on_edit`, `search_type` |
| `Text` | `<textarea>` | `editor` (es. `summernote`) + `editorOptions` (JSON), `maxlength` |
| `Email` / `Phone` / `Password` / `Color` | varianti di input tipizzato | come Varchar |
| `Integer` / `Decimal` / `Currency` | numerici | `Currency`: `currency_symbol` (`euro`\|`dollars`\|`custom`+`symbol_class`) |
| `Hidden` | input nascosto | `value`, `data-attrs` |
| `Value` | hidden + titolo visibile | `displayValue` |
| `Autocomplete` | typeahead | `autocomplete_options` (JSON), `readonly` |

### Multilingua (generano un sotto-campo per lingua: `name__it`, `name__en`, …)
| Tipo | Base per lingua |
|---|---|
| `VarcharLang` | `Varchar` |
| `TextLang` | `Text` (supporta `editor`) |
| `SlugLang` | `Slug` (supporta `input_src`) |
| `TagLang` | `Tag` |
| `ComboBoxLang` | `ComboBox` (option filtrate per `lang`) |

> I `*Lang` costruiscono internamente una `new Form` in `register()` e delegano render/validate/fillModel. NON aggiungere manualmente i suffissi `__it`: ci pensa il campo.

### Scelte
| Tipo | Uso | Config specifica |
|---|---|---|
| `Select` | dropdown | `type`: `standard` (con `query` SQL), `values` (con `resultSet`), `enum` (con `table`+`field_name`), `ajax` (con `ajaxCallClass`); `multiple`+`multiple-options`; `select2`; `readonly`; `disabled`. **Dettagli, esempi reali e insidie** → `references/select.md`. |
| `ComboBox` | select con ricerca (`data-admin-combobox`) | `type=values` + `resultSet` (opz. per `lang`) |
| `Radio` | radio button | `type` come Select; `media` (mostra immagini) |
| `Checkbox` | singola checkbox | `checkbox_value` (default 1) |
| `Published` | checkbox "attivo" con default a 1 | `checkbox_value` |

`resultSet` è un array di `['value'=>..., 'description'=>...]` (per `ComboBoxLang` anche `'lang'=>...`). Se manca `description` usa `admin::option.<value>`.

### Date / tempo
| Tipo | Uso | Config |
|---|---|---|
| `Date` | date picker | `type`: `date` (`DD-MM-YYYY`) o `datetime` (`DD-MM-YYYY HH:mm`) — converte in `Y-m-d` in `getRequestValue()` |
| `Daterange` | intervallo | intervallo di date |
| `Orario` / `Orari` | orari (giornalieri/settimanali) | strutture orario |

### Media / file
| Tipo | Uso | Config |
|---|---|---|
| `MediaLibrary` | upload Spatie MediaLibrary | `maxNumberOfFiles` (default 1), `allowedFileTypes` (`['jpg','png','webp',...]`), `maxFileSize`, `disableEditImage`. **Richiede** la collection in `registerMediaCollections()`. L'upload è possibile solo dopo il primo salvataggio (serve un `id`). **Dettagli, esempi reali e insidie** → `references/medialibrary.md`. |
| `File` / `Image` | upload semplice | tipi file |

### Speciali / strutturali
| Tipo | Uso | Config |
|---|---|---|
| `Sequence` | ordinamento numerico con auto-next | `min`, `max`, `step`, `table` — calcola il prossimo valore (+10) se nuovo/draft |
| `Slug` | slug con generazione da altro campo | `input_src` (campo sorgente), `table`, `foreign_key` |
| `Address` | indirizzo (package addresses) | `required`; richiede `HasAddresses` sul model |
| `Coords` | latitudine/longitudine | coordinate |
| `Tag` | tag input | tag |
| `Contents` | **blocchi di contenuto** (page_contents) | `moduleName`, `contentConfigs`, `viewsModuleName`. Vedi skill `master-page-content`. |
| `Crud` | tabella di un sotto-modulo collegato inline | `module`, `reference_key`. Funziona solo dopo il salvataggio (serve `id`). **Dettagli, esempi reali e insidie** → `references/crud.md`. |
| `Button` | pulsante azione | azione custom |

> Prima di inventare un tipo, controlla la cartella `Fields/` del package: c'è quasi sempre già il tipo giusto.

## 6. Comportamenti speciali da tenere a mente

Casi in cui il Field NON si comporta come un banale input:

1. **Campi `*Lang`** — non hanno una colonna propria; generano N sotto-campi `name__<lang>` e delegano tutto a una sotto-`Form`. La destinazione è la tabella `_translations`.
2. **`Select`/`Radio` multiple + `related`** — con `multiple => true` il name diventa `name[]` e i valori vanno nella tabella `_values`. Il model DEVE avere il campo in `protected $related`, altrimenti `saveData()` li ignora.
3. **`Sequence`** — in creazione o su record `draft` calcola automaticamente il prossimo valore; rispetta anche il filtro `parent` (sotto-moduli).
4. **`Date`** — mostra `DD-MM-YYYY` ma salva `Y-m-d` (override di `getValue`/`getRequestValue`). Non passare formati diversi.
5. **`Published`** — default a 1 se il valore è `null` (nuovo record nasce "attivo").
6. **`Checkbox`/`Published`** — se non spuntati NON inviano nulla nella Request: il valore resta il default DB / non aggiornato. Tienine conto nelle regole.
7. **`MediaLibrary` / `Crud`** — richiedono un `id` esistente: in creazione mostrano un messaggio "salva prima". Vanno tipicamente in un tab separato o dopo il primo save.
8. **`Value`/`Hidden`** — mostrano/inviano un valore ma spesso servono a portare in Request dati calcolati (`custom_value`, `displayValue`).
9. **`address_field`** — un campo può leggere il proprio valore dalla tabella indirizzi se `config('address_field')` è impostato e il model ha `getAddress()`.
10. **viewMode** — molti campi hanno un `renderViewMode()` dedicato; se crei un campo custom con markup complesso, implementalo o eredita il default (label + valore).

## 7. Creare un Field CUSTOM

> **PRIMA di creare un campo, verifica se ne esiste già uno simile — non reinventare la ruota.** Controlla nell'ordine: (1) i tipi del package in `Foundation/Form/Fields/` (catalogo §5); (2) i campi globali di progetto in `Master\Foundation\Form\Fields`; (3) i campi locali agli altri moduli (`Modules/*/Form/Fields/`). Se ne esiste uno riutilizzabile, usalo.
>
> Se serve una piccola variazione, valuta se puoi **riutilizzare il campo esistente con modifiche minime** (es. una nuova chiave di config opzionale, un ramo aggiuntivo) — **a condizione che NON cambino il comportamento per gli altri form che già lo usano**. Regole per una modifica sicura: retro-compatibile (nuove config opzionali con default che preservano il comportamento attuale), nessuna rinomina/rimozione di config o attributi esistenti, nessun cambio al `name`/output per i casi già in uso. Se la modifica rischia di rompere un altro form, NON toccare il campo condiviso: crea un nuovo campo (o estendi quello esistente in una sottoclasse).

Quando nessun tipo del package basta, scegli **dove** vive il campo:

- **Riusabile in più moduli** → globale di progetto:
  `private/master/Foundation/Form/Fields/<NomeTipo>.php`, namespace `Master\Foundation\Form\Fields`.
  In `config.php` lo usi col **nome breve**: `$form->addField('ColorSwatch', [...])`.
- **Specifico di un solo modulo** → locale al modulo:
  `private/master/Modules/<ModuleName>/Form/Fields/<NomeTipo>.php`, namespace `Master\Modules\<ModuleName>\Form\Fields`.
  In `config.php` lo usi con l'**FQCN**: `$form->addField(\Master\Modules\<ModuleName>\Form\Fields\<NomeTipo>::class, [...])`
  (esempio reale: `Modules/Roles/Form/Fields/Permissions.php`).

In entrambi i casi la classe estende `BaseField` ed è identica; cambia solo namespace/percorso e come la referenzi in `addField`. Esempio (versione globale):

```php
<?php

namespace Master\Foundation\Form\Fields;

use Master\Foundation\Form\Field as BaseField;

class ColorSwatch extends BaseField
{
    // (opz.) costruisci stato/sotto-campi una sola volta
    protected function register(): void
    {
        // es. leggere config, preparare opzioni
    }

    // OBBLIGATORIO: HTML dell'input. Usa SEMPRE getName()/getLabel()/getValue()/getHelp().
    public function render(): string
    {
        $value = ($this->config('valueLang'))
            ? $this->getValueLang($this->config('valueLang'))
            : $this->getValue();

        return '<div class="form-group">'
            . '<label>' . $this->getLabel() . '</label>'
            . '<input type="color" class="form-control ' . $this->config('customCssClasses') . '"'
            . ' value="' . htmlspecialchars($value, ENT_QUOTES) . '"'
            . ' name="' . $this->getName() . '" id="' . $this->getName() . '_field">'
            . $this->getHelp()
            . '</div>';
    }
}
```

Poi in `config.php`: `$form->addField('ColorSwatch', ['name' => 'brand_color', 'label' => '...']);`

Metodi che puoi (ri)definire — vedi `Field.php` per le firme:

- `render()` — **quasi sempre necessario**; markup dell'input.
- `renderViewMode()` — HTML in sola lettura (default: label + valore, con link se URL).
- `getValue()` / `getValueLang($lang)` — override per trasformare il valore letto dal model (es. `Date` formatta; `Select` risolve la description in viewMode).
- `getRequestValue()` — override per trasformare l'input prima del salvataggio (es. `Date` → `Y-m-d`).
- `modifyValidator($validator)` — override solo per regole particolari; il default applica `config('rules')`.
- `fillModel()` — override solo se il valore non va su una colonna diretta (es. i `*Lang` delegano alla sotto-Form). Il default fa `setAttributeIfExists(name, requestValue)`.
- `register()` — per campi compositi (crea una `new Form` e aggiungi sotto-campi con name `name__<lang>` o simili).

Convenzioni per un Field custom corretto:
- **Escapa sempre** i valori in output (`htmlspecialchars(..., ENT_QUOTES)`), come fanno `Varchar`/`Autocomplete`.
- Rispetta `customCssClasses`, `help`, `placeholder`, `readonly`, `disabled` se ha senso.
- Il markup admin è KTMetronic/Bootstrap 4: wrap in `.form-group`, `<label>`, `.form-control`.
- Se il campo è multilingua, imita `TextLang`/`SlugLang`: costruisci una sotto-`Form` in `register()` e delega `render`/`modifyValidator`/`fillModel`.
- Per valori NON su colonna diretta (traduzioni, valori, media) fai in modo che il `name` combaci con la convenzione (§2) e, se necessario, override `fillModel()`.
- **Mai JS/CSS dentro `render()`** (niente `<script>`, `<style>`, `onclick=`, `style=`): JS in `theme.js`/plugin `Admin`, CSS in `theme.css` o view Blade del modulo — vedi §7bis.
- NON modificare mai i file sotto `vendor/`. Un override si fa creando la classe omonima in `Master\Foundation\Form\Fields`.

## 7bis. JS e CSS dei campi: DOVE metterli (MAI nel form)

> **Regola assoluta**: il JavaScript non va MAI dentro il form / dentro `render()` del campo. Niente `<script>` inline, niente `onclick=` nel markup del Field. Idem per il CSS: niente `<style>` inline.

### JavaScript
Due destinazioni possibili:
1. **`assets/master/js/theme.js`** — JS globale dell'admin di progetto (crea il file se non esiste; vive accanto a `admin.js`/`custom.js` in `assets/master/js/`).
2. **Una view Blade dedicata nel modulo** (es. `Modules/<Nome>/Views/.../scripts.blade.php`) inclusa nella pagina admin — per JS specifico di quel modulo.

Usiamo **jQuery**. Esiste inoltre la libreria **`Admin`** (`assets/master/js/admin.js`) che gestisce il ciclo di vita dei plugin interni. Decisione da prendere caso per caso (spetta a chi sviluppa):

- **Intervento una tantum / specifico** → jQuery semplice in `theme.js` o nella `scripts.blade.php` del modulo.
- **Comportamento riusabile legato a un campo** → conviene trasformarlo in un **plugin `Admin`**:
  - ⚠️ **PRIMA di scrivere un plugin `Admin`, consulta la documentazione su Enesi Academy** per l'uso corretto delle funzioni di `admin.js` (`Admin.plug`, `Admin.load`, `Admin.on/trigger`, ecc.): usa `search_academy` / `get_doc` del MCP Enesi Academy. Questo passaggio serve **solo** quando stai creando un plugin `Admin` insieme al campo, non per un intervento jQuery una tantum.
  - il Field renderizza un attributo `data-admin-<nome>` sull'input (come fanno i campi del package: `data-admin-select2`, `data-admin-combobox`, `data-admin-slug`, `data-admin-datetimepicker`, `data-admin-media-library-input`, …);
  - registri il plugin con `Admin.plug('<nome>', function(context){ $(context).find('[data-admin-<nome>]').each(...) })`;
  - `Admin.load(context)` (ri)inizializza i plugin in un contesto — **fondamentale**: l'admin ricarica pezzi via AJAX (tab, tabelle CRUD, modali) e richiama `Admin.load()` sul nuovo DOM. Un plugin fatto così si re-inizializza da solo dopo ogni reload; una `$(document).ready` una tantum **no**.
  - eventi/azioni disponibili: `Admin.on/one/off/trigger`, `Admin.ajax`, `Admin.service`.

> Perché è importante per i campi: se il tuo Field custom aggancia JS con un `ready()` una tantum, dopo un reload AJAX del tab/della tabella CRUD il comportamento sparisce. Con `data-admin-*` + `Admin.plug` funziona sempre.

### CSS
Due destinazioni:
1. **`assets/master/css/theme.css`** — CSS globale dell'admin di progetto (crea il file se non esiste; accanto a `custom.css`).
2. **Una view Blade dedicata nel modulo** — per stili specifici del modulo.

Mai `style="..."` inline o `<style>` dentro `render()`.

## 8. Checklist per "aggiungere un campo"

0. **Esiste già un campo simile?** Cerca in package → globali di progetto → altri moduli. Riusalo se possibile; se basta una modifica minima e retro-compatibile a un campo esistente (senza rompere gli altri form che lo usano), procedi così invece di crearne uno nuovo (§7).
1. **Che dato è?** colonna diretta / multilingua / multi-valore / media / indirizzo / blocchi. → decide il tipo e la destinazione (§2).
2. **Esiste la destinazione?** migration + `$fillable` (o Translation `$fillable`, o `$related`, o media collection, o `HasAddresses`).
3. **Scegli il tipo** dal catalogo (§5). Multilingua → usa la variante `*Lang`.
4. `$form->addField('<Tipo>', ['name'=>..., 'label'=>..., 'rules'=>[...]])`.
5. **Referenzia il campo** in un `addTab(... 'nome|col:X' ...)`, altrimenti non appare.
6. **Regole** coerenti (ricorda: checkbox non spuntate non arrivano in Request).
7. Se serve un comportamento non coperto → **Field custom** in `Master\Foundation\Form\Fields` (§7). Fatto il Field, esegui `scripts/check-field-class-structure.php` e `scripts/check-field-no-inline-assets.php` sulla cartella `Form/Fields/` — non considerarlo finito finché non tornano puliti.
8. Svuota le cache admin se non vedi il campo: `php artisan config:clear && php artisan view:clear` (da `private/`).

## Riferimenti nel codice

- Classe base: `private/vendor/enesisrl/laravel-master-core/src/Foundation/Form/Field.php`
- Orchestratore + `addField`/layout/validazione: `.../Foundation/Form/Form.php`
- Tutti i tipi: `.../Foundation/Form/Fields/*.php`
- Salvataggio (traduzioni/valori/indirizzi): `.../Foundation/Modules/Base/Models/Model.php` (`saveData`)
- Esempi reali completi: `private/master/Modules/Projects/config.php`, `.../Pages/config.php`
- Model con `$fillable`/`$related`/media/`HasAddresses`: `private/master/Modules/Projects/Models/Project.php`
- Blocchi di contenuto (`Contents`): vedi skill `master-page-content`.
