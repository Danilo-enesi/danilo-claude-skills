# Regola: Beers accessibile (dialog, notifiche, errori dei form)

Beers (`assets/common/beers/beers.js`) mostra dialog, notifiche ed errori dei form. La versione del plugin (`templates/assets/common/beers/beers.js`) li rende accessibili; ogni modifica è marcata con un commento `// a11y:`.

| Funzione | Cosa fa la versione del plugin |
|---|---|
| `Beers.dialog` | `role="dialog"` `aria-modal="true"` sul box; al click di apertura ricorda chi l'ha aperto, porta il focus dentro (primo elemento focalizzabile o il box), **Esc chiude** (solo se il dialog è chiudibile), Tab e Shift+Tab restano dentro, alla chiusura **il focus torna al bottone che l'ha aperto**; bottone ✕ con `aria-label` |
| callback `notify` | contenitore `role="status"` `aria-live="polite"` (il lettore di schermo legge la notifica), ✕ con `type="button"` e `aria-label`, chiusura automatica in pausa anche con il focus da tastiera, non solo con il mouse |
| callback `alert.inline` | messaggio con `role="alert"`: letto appena compare |
| callback `form.error` | `aria-invalid="true"` sul campo e `aria-describedby` verso il messaggio (`id="bee-error-<campo>"`); tolti quando il campo cambia |
| callback `form.validatorErrors` | `aria-invalid` + `aria-describedby` verso `.invalid-feedback` (`id="invalid-<campo>"`, un contenitore per campo); corretto anche `globalMessages.lenght` → `length` (i messaggi senza campo non si vedevano mai) |

L'etichetta dei bottoni ✕ viene da `window.front.translations.beers.close` se la traduzione c'è, altrimenti «Chiudi».

## Nel progetto: controlla e, se manca, applica

Beers non ha versioni ed è adattata a ogni progetto: lo scaffold non la sovrascrive mai, e non va sostituita in blocco.

1. **Controlla**: `grep -c "a11y:" assets/common/beers/beers.js`, oppure `bash scripts/check-assets.sh <root>`. Ci sono i commenti `// a11y:` e `aria-modal`, `aria-live`, `aria-invalid` → è già a posto, non fare nulla.
2. **Manca** → applica le modifiche **funzione per funzione**: apri la versione del plugin, cerca ogni `// a11y:` e riporta quel pezzo nella stessa funzione del progetto (helper `a11yLabel` dopo `window.__`, poi `notify`, `alert.inline`, `form.error`, `form.validatorErrors`, `Beers.dialog`: `open`, `close`, `_focusables`, `_create`). Lascia com'è tutto il resto: le personalizzazioni del progetto restano.
3. Se una funzione del progetto è molto diversa da quella del plugin (riscritta, rinominata), applica lo stesso comportamento con il suo codice e dillo nel riepilogo.
4. Rigenera `base.min.js` (regola `assets-versioning`): in produzione gira il bundle, non `beers.js`.
5. **Prova** nel browser: apri un dialog con la tastiera (Tab fino al bottone, Invio), il focus è dentro; Tab gira solo dentro; Esc chiude; il focus torna sul bottone. Invia un form con errori: il lettore di schermo (o il pannello Accessibilità dei DevTools) legge il messaggio collegato al campo.

## Sì
- Dialog, modali e notifiche passano da Beers (o dai componenti di Bootstrap, che fanno già lo stesso): non se ne scrivono di nuove a mano.
- Traduzione `beers.close` in `window.front.translations` sui siti non italiani.

## No
- Niente `beers.js` del plugin copiato sopra quello del progetto.
- Niente dialog che si chiude con Esc quando è aperto con `close: false` (es. `alert.noclose`): lì l'utente deve scegliere un bottone.

Verifica: `scripts/check-assets.sh` (WARN se `beers.js` del progetto non ha le modifiche `a11y`), poi la prova del punto 5.
