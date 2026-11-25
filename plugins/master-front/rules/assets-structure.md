# Regola: cartelle degli asset

`assets/main/` = asset del tema **Main** del front.

```
assets/
├── main/
│   ├── css/              main.css, responsive.css, <modulo>.css, base.min.css, lang/<iso_code2>.css
│   ├── js/               main.js, <modulo>.js, base.min.js
│   ├── lib/<libreria>/   librerie scaricate (sottocartelle css/ js/ se sono tanti file)
│   ├── icons/            icone della web-app (favicon, apple-touch, ms-tile)
│   ├── images/<entità>/  immagini del progetto, per entità
│   │   ├── defaults/     immagini di default (jpg + webp)
│   │   └── icons/        icone usate nelle pagine (es. telefono)
│   ├── videos/           per entità se sono tanti
│   └── documents/        per entità se sono tanti, per estensione se sono pochi
├── common/beers/         Beers, libreria interna (js, css, immagini); senza versioni, adattata a ogni progetto: lo scaffold non la sovrascrive mai
└── mail/                 asset delle email inviate all'UTENTE (non quelle interne dell'admin)
```

## No
- Niente cartelle nuove (`assets/front/`, `assets/site/`...) quando il posto esiste già.
- Niente librerie in `css/` o `js/`: vanno in `lib/<libreria>/`.
- Niente `style.css`: il CSS globale si chiama `main.css`.
- In un repo esistente con un'altra struttura: adattati, non spostare file senza chiedere.

Verifica: `scripts/check-assets.sh`
