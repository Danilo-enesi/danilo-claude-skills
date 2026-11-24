# Regola: dati condivisi fra più Blade

Un dato che serve a più Blade si carica **una volta per richiesta, in un posto solo**.

| Dato | Dove |
|---|---|
| serve a viste precise (header, footer, menu, social) | **view composer** + builder singleton, registrato in `FrontServiceProvider::boot()` su un elenco esplicito di viste |
| fatto globale del sito (contatti, impostazioni) | `Front::loadSharedContent()` in `private/master/Foundation/Front.php` + `Dom::config('chiave')` |
| una sola pagina | controller → `view('...', [...])` |
| per il JS | `window.front` o `data-*` |

## No
- Niente query o `Model::` nelle Blade.
- Niente stesso array ricalcolato in ogni controller.
- Niente `View::composer('*', ...)`: colpisce anche mail e API.
- Niente roba pesante in `loadSharedContent()`: gira a ogni richiesta del front, API comprese.

Nessuno script: si controlla in review.
