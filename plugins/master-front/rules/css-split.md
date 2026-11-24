# Regola: cosa va in main / responsive / modulo

| File | Contiene |
|---|---|
| `main.js` | helper, init dei plugin, listener generici **e la logica delle pagine del front** (slider della home, filtri di una lista, form di contatto...) |
| `<modulo>.js` | solo una funzionalità **complessa e autonoma** che gestisce molte cose insieme: ecommerce (carrello, checkout), `map.js` (mappa, marker, filtri, popup)... |
| `main.css` | classi globali riusabili |
| `responsive.css` | **tutte** le media query, e solo quelle |
| `<modulo>.css` | stili di una funzionalità autonoma |

## Sì
- Breakpoint di Bootstrap, dal più largo: `1399.98`, `1199.98`, `991.98`, `767.98`, `575.98px`, più un livello extra **xs** per i dispositivi molto piccoli.
- Una classe globale fa sempre la stessa cosa: `.btn-black` è sempre nero.

## No
- Niente `@media` fuori da `responsive.css`.
- Niente override di una classe globale da una classe figlia, salvo quando è voluto ed evidente.
- Niente file modulo per codice generico o per la logica di una pagina: va in `main.*`. Un modulo nasce solo quando la funzionalità è complessa e starebbe male dentro `main.js`.

Verifica: `scripts/check-assets.sh`
