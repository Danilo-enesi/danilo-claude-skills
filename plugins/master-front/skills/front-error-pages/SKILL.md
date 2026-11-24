---
name: front-error-pages
description: Le due pagine che ogni front Master Laravel Enesi deve avere - `pages/errors.blade.php` (tutti i codici HTTP, resa dall'exception Handler del core con solo $exception ed $errors) e `pages/maintenance.blade.php` (503 di `php artisan down`, senza dati, solo traduzioni). Cosa ricevono, come adattarsi al codice, il view composer facoltativo per dati e meta, le chiavi di traduzione. Attivala quando crei o modifichi la pagina di errore o di manutenzione, o quando senti «pagina 404», «pagina di errore», «error page», «manutenzione», «php artisan down», «sito in aggiornamento».
---

# Pagine di errore e di manutenzione

**Regola d'oro:** ogni front ha `pages/errors.blade.php` e `pages/maintenance.blade.php`. La prima si adatta al codice che riceve; la seconda sta in piedi da sola, con le sole traduzioni.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Template: `templates/views/pages/errors.blade.php`, `templates/views/pages/maintenance.blade.php`, `templates/assets/main/css/maintenance.css` (li crea `/master-front:scaffold`).

## errors.blade.php

La rende l'exception Handler del core (vista `pages.errors`) per **qualsiasi** codice. Riceve solo:

| Variabile | Cosa è |
|---|---|
| `$exception` | l'eccezione HTTP: `getStatusCode()`, `getMessage()`, `getHeaders()` |
| `$errors` | un `ViewErrorBag` vuoto, perché il layout non si rompa se usa `$errors` |

- **Una pagina per tutti i codici**: titolo da `front::errors.title_<codice>` se la chiave esiste (`Lang::has(...)`), altrimenti `front::errors.generic_title` + `front::errors.generic_message`. Così un codice nuovo (418, 451...) ha comunque una pagina sensata, e basta aggiungere la sua chiave per dargli un titolo suo.
- Estende `layouts.main` (header, footer, stili del sito); link alla home con `Front::route('home')`.
- Niente `getMessage()` mostrato all'utente: può contenere dettagli tecnici.
- **Dati in più o meta** (titolo della pagina, `noindex`): un view composer su `pages.errors` nel `FrontServiceProvider` (o `AppServiceProvider` se manca), come in hpmotorrad-rent:
  ```php
  View::composer('pages.errors', function (ViewContract $view): void {
      $code = $view->getData()['exception']->getStatusCode();
      $known = Lang::has("front::errors.title_{$code}");
      $title = __($known ? "front::errors.title_{$code}" : 'front::errors.generic_title');

      Meta::set('title', $title);
      Meta::set('robots', 'noindex, nofollow');

      $view->with([
          'errorCode' => $code,
          'errorTitle' => $title,
          'errorMessage' => $known ? null : __('front::errors.generic_message'),
      ]);
  });
  ```
  Con il composer la vista usa `$errorTitle` / `$errorMessage` / `$errorCode` invece di calcolarli: non tenere le due logiche insieme.

## maintenance.blade.php

La rende il Handler del core per il 503 di `php artisan down`, **prima** di `Front::loadSharedContent()` e **senza dati**.

- Solo traduzioni (`@lang`, con la lingua esplicita per il blocco inglese: `@lang('front::maintenance.title', [], 'en')`).
- **Niente** `@extends`/layout, facade (`Front::`, `Meta::`, `Version::`, `Websites::`), componenti Blade (`<x-...>`), librerie, Beers, Google Fonts: il sito è giù, deve funzionare comunque.
- Stili solo in `assets/main/css/maintenance.css`, link diretto (senza `Version::get()`), colori e font di `DESIGN.md` scritti per esteso (le variabili sono in `main.css`, che qui non si carica).
- Logo con un `<picture>` statico (webp + jpg), non `<x-picture-webp>`.
- `<meta name="robots" content="noindex">`.

## Chiavi di traduzione

Le traduzioni del front si generano dal DB: aggiungi le chiavi in `app/Console/Commands/Utility/ln_upd.php` (una riga per lingua attiva) e lancia `php artisan ln:upd`; mai a mano in `resources/lang`.

| Chiave | Uso |
|---|---|
| `front::errors.title_<codice>` | titolo di un codice noto (400, 401, 403, 404, 405, 410, 413, 419, 429, 500, 502, 503...) |
| `front::errors.generic_title`, `front::errors.generic_message` | codice senza titolo suo |
| `front::errors.code` | «Errore :code» |
| `front::errors.back_home` | testo del link alla home |
| `front::maintenance.meta_title`, `.title`, `.text`, `.back_soon` | pagina di manutenzione |

## Verifica

- `bash scripts/check-views.sh <root>`: le due pagine esistono, la manutenzione non usa layout né facade.
- Prova vera: una URL inesistente (404) e, in locale, `php artisan down` / `php artisan up`.
