# Regola: rotte del front, un gruppo per lingua, percorsi tradotti

Le rotte del front stanno in `private/front/Main/Routes/web.php`.

## Struttura

```php
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
    Route::get('/blog', [BlogController::class, 'index'])->name('blog.index');
    Route::get('/blog/{rewurl}.html', [BlogController::class, 'show'])->name('blog.show');
});

// English
Route::group(['prefix' => 'en', 'as' => 'en.', 'locale' => 'en'], function () {
    Route::get('/', [PagesController::class, 'home'])->name('home');
    Route::get('/about-us', [PagesController::class, 'aboutUs'])->name('aboutUs');
    Route::get('/blog', [BlogController::class, 'index'])->name('blog.index');
    Route::get('/blog/{rewurl}.html', [BlogController::class, 'show'])->name('blog.show');
});
```

- Un gruppo per **ogni lingua front attiva del website**, con `prefix`, `as` e `locale` uguali al codice lingua.
- Dentro ogni gruppo le **stesse rotte con lo stesso nome**, ma il **percorso tradotto** nella lingua del gruppo (`/chi-siamo`, `/about-us`).
- Il gruppo `root.` e `PagesController@index` lavorano insieme (`controllers.md`): la richiesta alla root si elabora come `it`, poi il controller rimanda alla home nella lingua preferita.

## Sì
- Link nelle viste con `Front::route('aboutUs')` (lingua corrente) o `Front::routeLang('aboutUs', 'en')` (lingua precisa): mai URL scritti a mano.
- Rotta nuova → aggiungila in **tutti** i gruppi lingua, ognuna col suo percorso tradotto.
- Nomi delle rotte di entità come il resource controller: `<entità>.index`, `<entità>.show`.

## No
- Niente rotte del front fuori da un gruppo lingua (salvo la root).
- Niente percorso in italiano dentro il gruppo `en.` (o in un'altra lingua): ogni percorso è tradotto.
- Niente gruppo per una lingua che il website non ha attiva, e niente lingua attiva senza il suo gruppo.

Verifica: a mano.
