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

## Dettaglio di un'entità: valida `<slug>-<progId>`

Ogni handler che legge un parametro `{rewurl_<entità>}` (valore `<slug>-<progId>`, vedi `routes.md`), in quest'ordine:

1. **Trova per `progId`** (l'ultimo pezzo dopo `-`): non c'è → **404**.
2. **Attivo**: il record e **tutti i suoi padri** (categoria, sottocategoria, modello del prodotto...) devono essere attivi/pubblicati → altrimenti **404**.
3. **Slug giusto**: se l'URL richiesto è diverso da quello del record (`$model->url`, che contiene gli slug corretti suoi e dei padri) → **redirect 301** all'URL giusto. Così uno slug sbagliato con il `progId` giusto porta alla pagina corretta.
4. Canonical = `$model->url` (`meta.md`).

```php
public function show(Request $request, $rewurl_category, $rewurl_post) {
    $post = Blog::getByRewurlWithProgId($rewurl_post);              // cerca per progId
    abort_if(!$post, 404);
    abort_if(!$post->is_published_post, 404);                       // il record
    abort_if(!$post->category?->published, 404);                    // i padri

    if ($post->url !== $request->url()) {                           // slug (suo o dei padri) sbagliato
        return Response::redirectTo($post->url, 301);
    }

    Meta::set('canonical', $post->url);
    // ...
}
```

- Il lookup per `progId` sta nel model (`getByRewurlWithProgId`: `getByProgId(last(explode('-', $rewurl)))`), non ripetuto nei controller.
- Un `progId` non numerico è un 404, mai un errore 500.

## Sì
- Ogni metodo prepara i dati, imposta title, description e canonical (+ og:tags se servono, vedi `meta.md`) e rende la vista `pages/<entità>/<metodo>` (vedi `views-structure.md`).
- Entità nuova (blog, prodotti, progetti...) → controller nuovo, non metodi nuovi in `PagesController`.

## No
- Niente liste e dettagli di entità dentro `PagesController` (`PagesController@blog`, `PagesController@product`): vanno nel controller dell'entità.
- Niente nomi di metodo inventati quando esiste quello del resource controller (`list`, `detail` → `index`, `show`).
- Niente redirect della root con codice 301: la lingua dipende dal browser, il redirect non va messo in cache: 303.
- Niente dettaglio mostrato con lo slug sbagliato (contenuto duplicato): si rimanda con 301 all'URL giusto.
- Niente controllo di "attivo" solo sul record: anche i padri, sennò un prodotto di una categoria spenta resta raggiungibile.

Verifica: a mano.
