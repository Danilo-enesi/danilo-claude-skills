---
name: front-design
description: Come usare `DESIGN.md` (root del progetto, formato google-labs-code/design.md) per scrivere il CSS e l'HTML/Blade del front Master Laravel Enesi - token in variabili CSS generate da script, componenti di DESIGN.md come classi, markup che usa solo quelle classi, come aggiornare `DESIGN.md` (dove va ogni token, formato YAML, componenti, ordine delle sezioni, rinominare o togliere un token) a ogni modifica di design. Attivala quando crei o modifichi stili o markup del front a partire dal design, o quando cambi il design system: «fai il CSS di questa sezione», «crea la card / il bottone», «applica il design», «usa i colori del brand», «cambia il colore primario / il font», «nuovo componente grafico», «converti questo mockup», «aggiorna DESIGN.md», «aggiungi un colore al design system».
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

## 5. Aggiorna DESIGN.md

Nella **stessa modifica** in cui cambi il design, prima `DESIGN.md`, poi il CSS. Formato: https://github.com/google-labs-code/design.md (versione `alpha`).

### Quando

| Cambi nel front | In DESIGN.md |
|---|---|
| colore nuovo o cambiato | `colors` + riga in «Colors» |
| font, dimensione, peso, interlinea | `typography` + riga in «Typography» |
| container, breakpoint, spaziatura ricorrente | `spacing` + riga in «Layout» |
| raggio degli angoli | `rounded` + riga in «Shapes» |
| ombra, livelli | riga in «Elevation & Depth» |
| durata o curva di un'animazione | `motion` + riga in «Motion & Micro-interaction» |
| componente nuovo o cambiato (bottone, card...) | `components` + riga in «Components» |
| regola d'uso («il rosso solo per gli errori») | «Do's and Don'ts» |

### Come si scrive

- **Front matter YAML** fra `---` in cima: `version: alpha`, `name` (obbligatorio), poi i gruppi `colors`, `typography`, `rounded`, `spacing`, `motion`, `components`. Gruppi annidabili (`colors.brand.500`).
- **Tipi**: colore = qualsiasi colore CSS fra virgolette (`"#CC0001"`); misura = numero + `px`/`em`/`rem` (`8px`, `1.5rem`); durata = numero + `ms`; riferimento a un altro token = `"{colors.primary}"`.
- **Tipografia** = un oggetto per stile, con `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`:
  ```yaml
  typography:
    heading-lg:
      fontFamily: Barlow
      fontSize: 2rem
      fontWeight: 700
      lineHeight: 1.2
  ```
- **Componenti** = un nome con le sole proprietà ammesse (`backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`), valori quasi sempre riferimenti; le varianti sono voci a parte con nome affine:
  ```yaml
  components:
    button-primary:
      backgroundColor: "{colors.primary}"
      textColor: "{colors.on-primary}"
      rounded: "{rounded.md}"
      padding: 12px 24px
    button-primary-hover:
      backgroundColor: "{colors.primary-dark}"
  ```
- **Nomi**: minuscolo con `-`, per ruolo e non per aspetto (`primary`, `text-muted`, `button-primary`, non `rosso`, `grigio2`). Il nome diventa la variabile (`--color-text-muted`) e la classe (`.button-primary`).
- **Colori**: c'è sempre un `primary`; se ci sono colori, ci sono anche stili `typography` (il linter avvisa).
- **Sezioni** `##`, tutte facoltative ma **in quest'ordine**: Overview, Colors, Typography, Layout, Elevation & Depth, Shapes, Motion & Micro-interaction, Voice & Content Strategy, Components, Do's and Don'ts. Una frase concreta per voce: dove e perché si usa, non il valore (sta già nel YAML).
- **Mai doppioni**: una chiave YAML o un titolo di sezione ripetuti rendono il file non valido. Prima di aggiungere, cerca se esiste già (anche con un altro nome per lo stesso valore: riusa quello).

### Cambiare o togliere un token

- **Valore cambiato**: aggiorna il YAML e rilancia lo script; il CSS che usa la variabile si aggiorna da solo.
- **Rinominato**: cerca la vecchia variabile in CSS e Blade (`grep -rn -- '--color-vecchio' assets/main/css private/front/Main/Views`) e sostituiscila ovunque nella stessa modifica.
- **Tolto**: solo se nessun CSS usa più la sua variabile (stessa ricerca); altrimenti prima sostituisci gli usi.
- Dopo ogni modifica al YAML: `python -I scripts/design-tokens.py <root>/DESIGN.md --write <root>/assets/main/css/main.css`.

### Valori che non ci sono

- Valore del mockup vicino a un token esistente (es. `#CB0002` con `primary` `#CC0001`) → usa il token, è lo stesso colore.
- Valore davvero nuovo → aggiungilo con un nome di ruolo.
- Non è chiaro se sia nuovo o un errore del mockup → chiedi prima di aggiungerlo. Mai valori inventati.

## 6. Verifica

- `bash scripts/check-design.sh <root>` e `bash scripts/check-assets.sh <root>`.
- Facoltativo, il linter del formato: `npx -p @google/design.md designmd lint DESIGN.md`.

## No
- Niente esadecimali, `px` di design o nomi di font scritti nel CSS fuori dal blocco generato.
- Niente blocco `design-tokens` modificato a mano.
- Niente valore nuovo nel CSS senza la sua voce in `DESIGN.md`.
