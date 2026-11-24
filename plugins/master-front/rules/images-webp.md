# Regola: immagini statiche sempre con webp

## Sì
- Ogni jpg/png statico del front in `assets/main/images/` ha accanto il suo `.webp` con lo stesso nome.
- Le default (`images/defaults/`) sono **jpg + webp**.
- Nel markup: `<picture>` con `<source type="image/webp">` e il jpg/png come fallback.

## No
- Niente immagine statica senza webp. Mai.

Generare il webp: `cwebp -q 80 foto.jpg -o foto.webp` (o lo strumento del progetto).

Verifica: `scripts/check-assets.sh`
