# Regola: pagina di errore e di manutenzione

Ogni front ha `Views/pages/errors.blade.php` e `Views/pages/maintenance.blade.php` (le crea lo scaffold; dettagli nella skill `front-error-pages`).

## Sì
- `errors.blade.php`: una pagina per **tutti** i codici, con `$exception` (`getStatusCode()`...) ed `$errors` vuoto; titolo da `front::errors.title_<codice>` se esiste, altrimenti titolo e messaggio generici.
- Dati in più o meta della pagina di errore: un view composer su `pages.errors`.
- `maintenance.blade.php`: HTML completo e autonomo, solo traduzioni, stili in `assets/main/css/maintenance.css`, `noindex`.
- Chiavi `front::errors.*` e `front::maintenance.*` in `ln_upd.php`.

## No
- Niente pagina di errore per un solo codice che lascia gli altri senza pagina.
- Niente `getMessage()` dell'eccezione mostrato all'utente.
- Niente `@extends`, facade, componenti `<x-...>`, librerie o Google Fonts nella manutenzione: è resa senza dati, prima dei contenuti condivisi.

Verifica: `scripts/check-views.sh`
