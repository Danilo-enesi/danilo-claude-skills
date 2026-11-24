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

Prova: se per capire la Blade devi leggere PHP per più di una riga, quella riga va nel controller.

Verifica: `scripts/check-views.sh`
