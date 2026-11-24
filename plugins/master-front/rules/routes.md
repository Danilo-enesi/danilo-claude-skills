# Regola: rotte del front, un gruppo per lingua, percorsi tradotti

Le rotte del front stanno in `private/front/Main/Routes/web.php`.

## Struttura

```php
use Front\Main\Controllers\BlogController;
use Front\Main\Controllers\PagesController;
use Illuminate\Support\Facades\Route;

// Root: arriva come it, PagesController@index sceglie la lingua preferita e rimanda alla home
Route::group(['as' => 'root.', 'locale' => 'it'], function () {
    Route::get('/', [PagesController::class, 'index'])->name('index');
});

// Italiano
Route::group(['prefix' => 'it', 'as' => 'it.', 'locale' => 'it'], function () {
    Route::get('/', [PagesController::class, 'home'])->name('home');
    Route::get('/chi-siamo', [PagesController::class, 'aboutUs'])->name('aboutUs');
    Route::get('/blog', [BlogController::class, 'index'])->name('blog');
    Route::get('/blog/{rewurl_category}', [BlogController::class, 'index'])->name('blogByCategory');
    Route::get('/blog/{rewurl_category}/{rewurl_post}', [BlogController::class, 'show'])->name('post');
});

// English
Route::group(['prefix' => 'en', 'as' => 'en.', 'locale' => 'en'], function () {
    Route::get('/', [PagesController::class, 'home'])->name('home');
    Route::get('/about-us', [PagesController::class, 'aboutUs'])->name('aboutUs');
    Route::get('/blog', [BlogController::class, 'index'])->name('blog');
    Route::get('/blog/{rewurl_category}', [BlogController::class, 'index'])->name('blogByCategory');
    Route::get('/blog/{rewurl_category}/{rewurl_post}', [BlogController::class, 'show'])->name('post');
});
```

- Un gruppo per **ogni lingua front attiva del website**, con `prefix`, `as` e `locale` uguali al codice lingua.
- Dentro ogni gruppo le **stesse rotte con lo stesso nome**, ma il **percorso tradotto** nella lingua del gruppo (`/chi-siamo`, `/about-us`).
- Il gruppo `root.` e `PagesController@index` lavorano insieme (`controllers.md`): la richiesta alla root si elabora come `it`, poi il controller rimanda alla home nella lingua preferita.

## Nomi e percorsi

| | Formato | Esempi |
|---|---|---|
| nome (`->name()`) | **inglese**, breve, facile da scrivere e da capire, uguale in tutte le lingue | `home`, `aboutUs`, `blog`, `post`, `productsByCategory`, `product` |
| percorso | **minuscolo**, parole separate da `-` (`<parola>-<parola>`), tradotto nella lingua del gruppo, URL friendly: niente accenti, spazi, maiuscole, `_` | `/chi-siamo` · `/about-us` · `/quienes-somos` |

## Parametri delle entità: un solo parametro `<slug>-<progId>`

Un'entità nell'URL è **un solo parametro** `{rewurl_<entità>}` il cui valore è `<slug>-<progId>` (es. `{rewurl_post}` = `guida-alla-manutenzione-42`). Lo slug è quello della lingua corrente, il `progId` identifica il record.

```php
Route::get('/shop/{rewurl_category}/{rewurl_product_model}/{rewurl_product}', [ProductsController::class, 'show'])->name('product');
```

- L'URL lo costruisce il model (accessor `url`): `Front::route('post', ['rewurl_category' => $category->meta_rewurl . '-' . $category->progId, 'rewurl_post' => $this->meta_rewurl . '-' . $this->progId])`.
- Il controller che legge il parametro valida slug e `progId` contro il DB (`controllers.md`).

## Sì
- Link nelle viste con `Front::route('aboutUs')` (lingua corrente) o `Front::routeLang('aboutUs', 'en')` (lingua precisa), o con `$model->url` per le entità: mai URL scritti a mano.
- Rotta nuova → aggiungila a mano in **tutti** i gruppi lingua, ognuna col suo percorso tradotto.

## No
- Niente rotte del front fuori da un gruppo lingua (salvo la root).
- Niente percorso in italiano dentro il gruppo `en.` (o in un'altra lingua): ogni percorso è tradotto.
- Niente gruppo per una lingua che il website non ha attiva, e niente lingua attiva senza il suo gruppo.
- Niente `foreach` sulle lingue per generare i gruppi: ogni lingua ha i suoi percorsi tradotti, un ciclo darebbe a tutte lo stesso percorso. Un gruppo scritto a mano per lingua.
- Niente slug e id in due parametri (`/blog/{slug}/{id}`) né id da solo (`/blog/{id}`): un parametro `<slug>-<progId>`.
- Niente nomi di rotta in italiano o criptici (`dettaglio`, `pg2`), né percorsi con maiuscole, `_` o accenti (`/Chi_Siamo`, `/perché`).

Verifica: a mano.
