---
name: front-design
description: Come usare `DESIGN.md` (root del progetto, formato google-labs-code/design.md) per scrivere il CSS e l'HTML/Blade del front Master Laravel Enesi - token in variabili CSS generate da script, componenti di DESIGN.md come classi, markup che usa solo quelle classi, DESIGN.md aggiornato a ogni modifica di design. Attivala quando crei o modifichi stili o markup del front a partire dal design: «fai il CSS di questa sezione», «crea la card / il bottone», «applica il design», «usa i colori del brand», «cambia il colore primario / il font», «nuovo componente grafico», «converti questo mockup».
---

# CSS e HTML da DESIGN.md

**Regola d'oro:** ogni valore di design (colore, font, misura, raggio, durata) viene da `DESIGN.md`. Nel CSS si usa la sua variabile, mai il valore scritto a mano; se il valore non c'è, prima lo aggiungi a `DESIGN.md`.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Regola: `rules/design-md.md`.

## 1. Leggi DESIGN.md

- **Front matter YAML** = i valori esatti: `colors`, `typography`, `rounded`, `spacing`, `motion`, `components`.
- **Sezioni** (Overview, Colors, Typography, Layout, Components, Do's and Don'ts...) = quando e come usarli. Le leggi prima di scegliere un colore o uno stile: dicono, per esempio, che `primary` è solo per le call to action.
- Un riferimento `{colors.primary}` è un altro token, non un testo.

## 2. Token → variabili CSS (script, mai a mano)

```bash
python -I scripts/design-tokens.py <root>/DESIGN.md --write <root>/assets/main/css/main.css
```

Scrive (o riscrive) in cima a `main.css` il blocco `:root` fra `design-tokens: start` / `end`. Nomi fissi:

| Token | Variabile |
|---|---|
| `colors.primary`, `colors.brand.500` | `--color-primary`, `--color-brand-500` |
| `typography.body-md.fontFamily` / `fontSize` / `fontWeight` / `lineHeight` | `--font-body-md-family` / `-size` / `-weight` / `-line-height` |
| `rounded.md` | `--radius-md` |
| `spacing.lg` | `--space-lg` |
| `motion.fast.duration` | `--motion-fast-duration` |

- Il blocco generato **non si tocca a mano**: si cambia `DESIGN.md` e si rilancia lo script.
- Le altre variabili del progetto (es. quelle del template, `--color-text`) restano fuori dal blocco; se corrispondono a un token, sostituiscile con quella del token.

## 3. Scrivi il CSS

- Solo variabili: `color: var(--color-primary)`, `border-radius: var(--radius-md)`, `font-family: var(--font-body-md-family), sans-serif` (il fallback generico va sempre).
- Uno stile tipografico = una classe che ne usa tutte le variabili:
  ```css
  .text-body-md {
    font-family: var(--font-body-md-family), sans-serif;
    font-size: var(--font-body-md-size);
    line-height: var(--font-body-md-line-height);
  }
  ```
- **Componenti di DESIGN.md** (`components.button-primary: { backgroundColor, textColor, rounded, padding, typography }`) → una classe con lo stesso nome, ogni proprietà dalla variabile del token:
  ```css
  .button-primary {
    background-color: var(--color-primary);
    color: var(--color-on-primary);
    border-radius: var(--radius-md);
    padding: var(--space-sm) var(--space-md);
  }
  ```
  Le varianti (`button-primary-hover`, `button-secondary`) sono classi o stati (`:hover`) della stessa famiglia.
- Dove va (`rules/css-split.md`): classi globali e componenti in `main.css`, **tutte** le media query in `responsive.css` con i breakpoint della sezione Layout (o quelli di Bootstrap della regola), stili di una funzionalità autonoma in `<modulo>.css`.

## 4. Scrivi l'HTML / Blade

- Il markup usa **solo le classi** del passo 3: niente `style=""` con colori o misure, niente classi inventate per un caso solo (`rules/no-inline.md`).
- Lo stesso pezzo in due viste è un componente Blade in `components/<concetto>/` (`rules/components-reuse.md`); il nome del componente Blade segue quello di DESIGN.md (`<x-ui.button-primary>` ↔ `components.button-primary`).
- Testi con `@lang`, attributi con `{{ __() }}` (`rules/translations.md`); immagini con `<x-picture-webp>`.

## 5. Tieni DESIGN.md aggiornato

Nella **stessa modifica** in cui cambi il design:
- valore nuovo o cambiato (colore, font, misura) → prima in `DESIGN.md` (front matter + una riga nella sezione), poi rilancia lo script;
- componente nuovo → voce in `components` + la riga in «Components»;
- regola d'uso nuova («il rosso solo per gli errori») → in «Do's and Don'ts».

Se un valore del mockup non corrisponde a nessun token e non è chiaro se sia nuovo o un errore, chiedi prima di aggiungerlo.

## 6. Verifica

- `bash scripts/check-design.sh <root>` e `bash scripts/check-assets.sh <root>`.
- Facoltativo, il linter del formato: `npx -p @google/design.md designmd lint DESIGN.md`.

## No
- Niente esadecimali, `px` di design o nomi di font scritti nel CSS fuori dal blocco generato.
- Niente blocco `design-tokens` modificato a mano.
- Niente valore nuovo nel CSS senza la sua voce in `DESIGN.md`.
