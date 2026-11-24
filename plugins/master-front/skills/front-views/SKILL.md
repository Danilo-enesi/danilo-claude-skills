---
name: front-views
description: Come scrivere le viste Blade del front Master Laravel Enesi (`private/front/Main/Views/`): in quale cartella va il file (layouts, partials, components, pages/<entità>), direttive Blade invece di PHP crudo, niente logica complessa né CSS/JS inline. Attivala quando crei o modifichi una pagina, un partial, un componente o una vista del front: «nuova pagina», «crea la vista», «partial», «componente Blade», «sposta questa logica fuori dalla vista».
---

# Viste del front

**Regola d'oro:** la Blade mostra dati già pronti. Cartella giusta, direttive Blade, nessuna logica complessa.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. **Scegli la cartella** (`rules/views-structure.md`):
   - pagina → `pages/<entità>/index|show|create|edit.blade.php`
   - pezzo globale (header, footer, modale, form) → `partials/`
   - pezzo riusabile (bottone, card, titolo) → `components/<concetto>/` (generici nella radice di `components/`)
   - in `layouts/` **solo layout**.
   - email (template, blocchi, layout della mail) → skill `front-mail`.
   - lo stesso pezzo serve in due viste → un solo componente in `components/`, richiamato con `<x-...>`; prima cerca se esiste già (`rules/components-reuse.md`).
   - componente con molta logica → class based component (classe in `private/front/Main/Components/`), registrato con `Blade::component(...)` nel `FrontServiceProvider`, o nell'`AppServiceProvider` se il primo non c'è.
2. **Estendi il layout**: `@extends('layouts.main')` + `@section('content')`.
3. **Prepara i dati nel controller** (skill `front-routes` per controller e rotta; o in un viewController): query, filtri, ordinamenti, `->with()` (`rules/blade-logic.md`).
4. **Scrivi il markup con le direttive Blade**: `@if`, `@foreach`, `@class`, `@selected`, `@json`... (`rules/blade-directives.md`).
5. **Traduzioni** (`rules/translations.md`): testo → `@lang('front::…')`, attributi (`title`, `alt`, `data-*`…) → `{{ __('front::…') }}`.
6. **CSS/JS di pagina**: file in `assets/main/` + `@push('styles')` / `@push('scripts')` (`rules/no-inline.md`).
7. **Verifica**: `bash scripts/check-views.sh <root>`.

## No
- Niente stessa card (o pezzo) copiata in due viste: è un componente.
- Niente `<?php ?>`, query, `->map()`/`->filter()` nella Blade.
- Niente `<style>`, `<script>`, `onclick=` nella Blade.
