# Regola: struttura delle Views

`private/front/Main/Views/` (tema **Main**) ha cinque cartelle fisse.

| Cartella | Contiene |
|---|---|
| `layouts/` | **solo layout**: `main.blade.php` (stesso nome del tema) e layout alternativi o vuoti del sito |
| `partials/` | partial globali: header, footer, modali, form... |
| `partials/base/` | `head.blade.php` e `scripts.blade.php` |
| `components/<concetto>/` | componenti riusabili raggruppati per concetto (`blog/`, `ecommerce/`, `blocks/`...); i generici nella radice (`components-reuse.md`) |
| `mail/` | tutto ciò che riguarda le email: template, blocchi, layout delle mail (CSS inline ammesso; il design può vivere nell'admin, vedi `mail.md`) |
| `pages/<entità>/` | pagine, per entità, nomi da resource controller: `index`, `create`, `show`, `edit` |

## Sì
- Pagina statica → `pages/<entità>/index.blade.php`.
- Se tutto il progetto ha già un'altra convenzione per le pagine, seguila.

## No
- Niente template o blocchi di email fuori da `mail/` (né in `partials/` né in `components/`).
- Niente partial, head o scripts in `layouts/`: un layout si usa con `@extends`, mai con `@include`.
- Niente cartella `base/` con il layout dentro: è la struttura vecchia.

Verifica: `scripts/check-views.sh`
