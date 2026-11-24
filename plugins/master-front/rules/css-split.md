# Regola: cosa va in main / responsive / modulo

| File | Contiene |
|---|---|
| `main.js` | script globali: helper, init dei plugin, listener generici |
| `<modulo>.js` | una funzionalità autonoma (`map.js`, `auth.js`...) |
| `main.css` | classi globali riusabili |
| `responsive.css` | **tutte** le media query, e solo quelle |
| `<modulo>.css` | stili di una funzionalità autonoma |

## Sì
- Breakpoint di Bootstrap, dal più largo: `1399.98`, `1199.98`, `991.98`, `767.98`, `575.98px`, più un livello extra **xs** per i dispositivi molto piccoli.
- Una classe globale fa sempre la stessa cosa: `.btn-black` è sempre nero.

## No
- Niente `@media` fuori da `responsive.css`.
- Niente override di una classe globale da una classe figlia, salvo quando è voluto ed evidente.
- Niente file modulo per codice generico: va in `main.*`.

Verifica: `scripts/check-assets.sh`
