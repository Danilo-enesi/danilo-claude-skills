---
name: front-routes
description: Controller e rotte del front Master Laravel Enesi: un controller per entità con i metodi del resource controller, PagesController per le pagine statiche e la home, redirect della root alla lingua preferita, `Routes/web.php` con un gruppo per lingua e percorsi tradotti. Attivala quando aggiungi una pagina o una rotta del front, crei un controller, tocchi la home o la root: «nuova rotta», «nuova pagina», «crea il controller», «route della home», «redirect della root», «traduci l'url», «aggiungi una lingua al front».
---

# Controller e rotte del front

**Regola d'oro:** un controller per entità, `PagesController` solo per le pagine statiche; ogni rotta esiste in tutti i gruppi lingua, con il percorso tradotto.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. **Scegli il controller** (`rules/controllers.md`), in `private/front/Main/Controllers/`:
   - pagina statica (home, chi siamo, privacy...) → `PagesController`;
   - lista/dettaglio di un'entità → `<Entità>Controller@index` / `@show` (crealo se manca).
2. **Scrivi il metodo**: dati, poi title, description e canonical con `Meta::set(...)` (+ og:image/og:type se servono, skill `front-meta`), poi `return view('pages.<entità>.<metodo>', [...])`.
3. **Aggiungi la rotta** in `private/front/Main/Routes/web.php` (`rules/routes.md`), in **ogni** gruppo lingua:
   - nome (`->name()`) in **inglese**, breve e chiaro, uguale in tutte le lingue;
   - percorso **minuscolo** `<parola>-<parola>`, tradotto nella lingua del gruppo, URL friendly;
   - entità = **un solo parametro** `{rewurl_<entità>}` con valore `<slug>-<progId>`.
4. **Dettaglio di un'entità** (`rules/controllers.md`): trova per `progId` → 404 se manca; record **e padri** attivi → sennò 404; `$model->url !== $request->url()` → redirect 301 all'URL con lo slug giusto; canonical `$model->url`.
5. **Home**: `PagesController@home` nei gruppi lingua. Se la home è la prima pagina che vede l'utente, servono **insieme**:
   - il gruppo `root.` con `Route::get('/', [PagesController::class, 'index'])->name('index')`;
   - `PagesController@index` con il redirect 303 alla lingua preferita (codice in `rules/controllers.md`). Se ne esiste già uno diverso, sostituiscilo per intero con il nostro.
6. **Link** nelle viste: `Front::route('nome')`, mai URL a mano.

## No
- Niente liste o dettagli di entità in `PagesController`.
- Niente rotta presente in una lingua sola, né percorso non tradotto.
- Niente `foreach` sulle lingue in `web.php`: i percorsi uscirebbero uguali per tutte.
- Niente slug e id in due parametri, niente nomi di rotta in italiano, niente percorsi con maiuscole, `_` o accenti.
