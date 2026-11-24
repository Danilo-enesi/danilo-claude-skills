# Regola: traduzioni nelle Blade del front

| Dove | Usa |
|---|---|
| testo di un elemento | `@lang('front::gruppo.chiave')` |
| valore di un attributo: `title`, `alt`, `aria-label`, `placeholder`, `data-*`, `content`... | `{{ __('front::gruppo.chiave') }}` |
| testo che deve essere escapato (contiene valori dell'utente o caratteri HTML) | `{{ __('front::gruppo.chiave', ['nome' => $nome]) }}` |
| plurale | `@choice('front::gruppo.chiave', $n)` |

`@lang` stampa **senza escape**; `{{ __() }}` escapa l'HTML. Dentro un attributo l'escape serve sempre.

## No
- Niente `@lang` dentro un attributo (FAIL).
- Niente testo fisso nelle viste: ogni etichetta è una chiave `front::`.
- Niente modifiche a mano ai file di `resources/lang`: le traduzioni si gestiscono nel DB (ResourcesLang) e i file si rigenerano.

Verifica: `scripts/check-views.sh`
