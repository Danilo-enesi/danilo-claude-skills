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
   - **prima di scrivere un blocco** cerca la sua classe radice nelle altre viste (`grep -rn 'class="[^"]*<classe>' Views/`): stesso scheletro (tag e classi) con immagini, link o testi diversi è lo **stesso componente**, le differenze diventano props (`rules/components-reuse.md`). Questo controllo lo fai **tu, leggendo le viste, sempre**: lo script trova solo le copie esatte, e se vale la pena farne un componente lo decidi tu con i criteri della regola.
   - componente con molta logica → class based component (classe in `private/front/Main/Components/`), registrato con `Blade::component(...)` nel `FrontServiceProvider`, o nell'`AppServiceProvider` se il primo non c'è.
2. **Estendi il layout**: `@extends('layouts.main')` + `@section('content')`.
3. **Prepara i dati nel controller** (skill `front-routes` per controller e rotta; o in un viewController): query, filtri, ordinamenti, `->with()`, e i dati da passare ai componenti (breadcrumb, titolo, immagine) già validati: la vista riceve `$breadcrumb`, non costruisce l'array (`rules/blade-logic.md`).
4. **Scrivi il markup** semantico e accessibile (skill `front-html`) **con le direttive Blade**: `@if`, `@foreach`, `@class`, `@selected`, `@json`... (`rules/blade-directives.md`).
5. **Traduzioni** (`rules/translations.md`): testo → `@lang('front::…')`, attributi (`title`, `alt`, `data-*`…) → `{{ __('front::…') }}`.
6. **CSS/JS di pagina**: file in `assets/main/` + `@push('styles')` / `@push('scripts')` (`rules/no-inline.md`); pagina con molte librerie o molto JS suo → `pages/<entità>/scripts.blade.php` + `assets/main/js/pages/<entità>.js` (`rules/scripts-loading.md`). Immagini, iframe e video: skill `front-performance`.
7. **Verifica**: `bash scripts/check-views.sh <root>`, poi rileggi tu le viste per il riuso dei componenti (passo 1): l'assenza di WARN non lo sostituisce.

## No
- Niente stessa card (o pezzo) copiata in due viste: è un componente.
- Niente stesso scheletro (stessi tag e classi) in due viste solo perché cambiano immagini, link o testi: sono props dello stesso componente.
- Niente `<?php ?>`, query, `->map()`/`->filter()` nella Blade.
- Niente array costruiti nella vista per le props (`:breadcrumb="[__(...) => Front::route(...), ...]"`): li prepara e valida il controller.
- Niente `<style>`, `<script>`, `onclick=` nella Blade.
