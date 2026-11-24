# Regola: un controller per entità, PagesController per le pagine statiche

I controller del front stanno in `private/front/Main/Controllers/` (namespace `Front\Main\Controllers`).

| Controller | Contiene |
|---|---|
| `PagesController` | pagine statiche: home, chi siamo, contatti, privacy, cookie... e il redirect della root (`index`) |
| `<Entità>Controller` | una entità, con i metodi del **resource controller**: `index` (lista), `show` (dettaglio), `create`, `store`, `edit`, `update`, `destroy` |

Esempi: `BlogController@index` / `BlogController@show`, `ProductsController@index` / `ProductsController@show`, `UserController` per l'area utente.

## Home e redirect della root

La home vive in `PagesController@home`. Se la home è la prima pagina che vede l'utente, la root `/` non mostra nulla: `PagesController@index` sceglie la lingua preferita fra quelle attive del website e rimanda alla home in quella lingua. Lavora insieme al gruppo `root.` di `routes.md`. Se `PagesController` ha già un metodo `index` (versioni vecchie, altre logiche di redirect), **va sostituito per intero** con questo: non si fonde, non se ne tengono pezzi.

```php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;
use Master\Facades\Front;
use Master\Modules\Websites\Facades\Websites;

public function index(Request $request) {
    $langs = array_keys(Websites::current('enabledFrontLanguages') ?: []);

    if (empty($langs)) {
        abort(500, 'Nessuna lingua front attiva sul website.');
    }

    $lang = $request->getPreferredLanguage($langs);

    return Response::redirectTo(Front::routeLang('home', $lang), 303);
}
```

## Sì
- Ogni metodo prepara i dati, imposta title, description e canonical (+ og:tags se servono, vedi `meta.md`) e rende la vista `pages/<entità>/<metodo>` (vedi `views-structure.md`).
- Entità nuova (blog, prodotti, progetti...) → controller nuovo, non metodi nuovi in `PagesController`.

## No
- Niente liste e dettagli di entità dentro `PagesController` (`PagesController@blog`, `PagesController@product`): vanno nel controller dell'entità.
- Niente nomi di metodo inventati quando esiste quello del resource controller (`list`, `detail` → `index`, `show`).
- Niente redirect della root con codice 301: la lingua dipende dal browser, il redirect non va messo in cache: 303.

Verifica: a mano.
