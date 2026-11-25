# Regola: niente logica complessa nelle Blade

Elaborazione dei dati e logica PHP **complessa** solo nel **controller** o in una **classe viewController**. La Blade riceve i dati già pronti.

## Sì, nella Blade
- `@if` / `@unless` / `@isset` semplici.
- `@foreach` / `@forelse`, anche con un `@if` dentro.
- Lettura di proprietà e relazioni già caricate: `$tour->translation->title`.
- Formattazione banale di un valore: `{{ $date->format('d/m/Y') }}`.

## No, nella Blade
- Query: `Model::where(...)`, `->get()`, `DB::...` (FAIL).
- Trasformazioni di collezioni: `->map()`, `->filter()`, `->groupBy()`, `->sortBy()`, `collect(...)` (WARN: spostale nel controller).
- Calcoli su più passaggi, `@php` con logica, funzioni definite nella vista.
- Relazioni caricate in lazy-load dentro un `@foreach` (N+1): `->with()` nel controller.

- Strutture dati costruite nella vista per passarle a un componente: array letterali con traduzioni, rotte, catene `?->`, cast (WARN).

## Dati per i componenti: una variabile dal controller

Breadcrumb, titolo, immagine, link... che una vista passa a un componente si preparano **nel controller** e arrivano alla vista come variabile. La vista passa solo quella.

```blade
{{-- No: la vista costruisce il breadcrumb, nessuno controlla che i pezzi esistano --}}
<x-page-title :breadcrumb="[__('front::brands.title') => Front::route('brands'), (string) $brand->translation?->description => null]" />

{{-- Sì --}}
<x-page-title :title="$title" :breadcrumb="$breadcrumb" />
```

```php
// Controller: qui si valida. Senza traduzione nella lingua corrente il record non si mostra (o usa un fallback deciso, mai una stringa vuota).
$name = $brand->translation?->description;
abort_if(blank($name), 404);

$breadcrumb = [
    __('front::brands.title') => Front::route('brands'),
    $name                     => null,                        // ultima voce: pagina corrente, senza link
];

return view('pages.brands.show', [
    'brand'      => $brand,
    'title'      => $name,
    'breadcrumb' => $breadcrumb,
]);
```

Perché: la vista si legge senza decifrare PHP, e il controller è l'unico posto dove un valore mancante diventa una decisione (404, fallback, redirect) invece di un `(string) null` che stampa una voce vuota. Lo stesso array serve anche ai dati strutturati (`BreadcrumbList`) senza ricostruirlo.

Se più action costruiscono lo stesso breadcrumb, un metodo privato del controller (o del model, se dipende solo dal record) lo prepara una volta.

Prova: se per capire la Blade devi leggere PHP per più di una riga, quella riga va nel controller.

Verifica: `scripts/check-views.sh` trova query, pipeline di collezioni e array letterali nelle props; il resto (logica nascosta in una riga lunga, dati non validati) lo verifica l'agente rileggendo vista e controller.
