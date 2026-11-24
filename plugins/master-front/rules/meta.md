# Regola: meta tag

## Sì
- `{!! Meta::render() !!}` in head stampa tutto: title, description, canonical, robots, OpenGraph, Twitter.
- Ogni action che rende una pagina imposta **nel controller**, prima di `view()`: `Meta::set('title', ...)` e `Meta::set('description', ...)`, più `Meta::set('og:image', ...)` se c'è una cover.
- Dal CMS: campo meta con fallback, `$model->meta_title ?: $model->description`.

## No
- Niente `<title>`/`<meta>` a mano nelle viste.
- Niente troncamenti a mano: `Meta` taglia già a 160 caratteri.
- Una chiave nuova (es. `theme-color`) non si stampa nella vista: si estende la mappa in `private/master/Foundation/Meta.php`.

Nessuno script: si controlla in review.
