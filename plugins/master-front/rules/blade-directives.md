# Regola: direttive Blade, non PHP crudo

Nelle Blade usa le direttive del framework. Il PHP crudo è l'ultima scelta.

| Invece di | Usa |
|---|---|
| `<?php if (...): ?>` / `<?php foreach ...` | `@if` / `@foreach` / `@forelse ... @empty` |
| `<?php echo $x; ?>` | `{{ $x }}` (`{!! !!}` solo per HTML fidato) |
| `class="a <?php if ($on) echo 'b'; ?>"` | `@class(['a', 'b' => $on])` |
| `style` composto a mano | `@style([...])` |
| `selected` / `checked` / `disabled` a mano | `@selected($x)` / `@checked($x)` / `@disabled($x)` |
| `{!! json_encode($x) !!}` | `@json($x)` o `{{ Js::from($x) }}` |
| `<?php if (isset($x)) ?>` / `empty` | `@isset($x)` / `@empty($x)` |
| controllo di ambiente | `@env('local')` / `@production` |
| utente loggato | `@auth` / `@guest` |
| `<?php $x = ...; ?>` | il dato arriva pronto dal controller o dal composer |

## No
- Niente `<?php ?>` nelle Blade (FAIL).
- `@php ... @endphp` solo per una variabile locale banale; logica e query no (WARN).

Verifica: `scripts/check-views.sh`
