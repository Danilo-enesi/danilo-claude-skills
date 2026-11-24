---
name: front-assets
description: Dove vanno gli asset del front Master Laravel Enesi: `assets/main/` (css, js, lib, icons, images per entità, videos, documents), `assets/common/beers/`, `assets/mail/`; cosa va in main.js / main.css / responsive.css e quando creare un file modulo (map.js, map.css); immagini statiche sempre con webp. Attivala quando crei o salvi un file in `assets/`: «dove metto questo CSS/JS», «aggiungo una libreria», «salvo un'immagine», «immagine default», «webp», «media query», «responsive.css», «icone», «Beers», «asset delle email».
---

# Asset del front

**Regola d'oro:** `assets/main/` è la cartella del tema **Main**. Ogni file ha un posto fisso.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. **Trova il posto** (`rules/assets-structure.md`):
   - nostro CSS/JS → `assets/main/css/`, `assets/main/js/`
   - libreria scaricata → `assets/main/lib/<libreria>/`
   - immagine → `assets/main/images/<entità>/` (default in `defaults/`, icone di pagina in `icons/`)
   - icone della web-app → `assets/main/icons/`
   - Beers → `assets/common/beers/`
   - email per l'utente → `assets/mail/`
2. **Scegli il file** (`rules/css-split.md`):
   - codice generico **e logica delle pagine** → `main.js` / `main.css`
   - funzionalità **complessa e autonoma** (ecommerce, mappa con marker e filtri...) → `<modulo>.js` / `<modulo>.css`
   - media query → **solo** `responsive.css`
3. **Immagine statica**: salva anche il `.webp` (`rules/images-webp.md`).
4. **Caricalo**: in head o scripts con `Version::get()` e nel bundle minificato (skill `front-head` / `front-scripts`).
5. **Verifica**: `bash scripts/check-assets.sh <root>`.

## No
- Niente cartelle nuove in `assets/` se il posto esiste già.
- Niente `@media` in `main.css` o nei moduli.
- Niente immagine statica senza webp.
