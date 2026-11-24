---
name: front-cdn
description: Prima di installare o caricare una libreria/plugin JS o CSS nel front Master Laravel Enesi (jQuery, Bootstrap, Swiper, Fancybox, Select2, Font Awesome...), controlla se è sulla CDN interna cdn.ene.si con `scripts/cdn.sh <nome>`, che restituisce solo l'URL e le versioni, senza leggere la lista intera. Attivala quando senti «installa/aggiungi/carica la libreria X», «serve un carousel/lightbox/datepicker», «npm install X» per il front, «metto X in assets/main/lib», «che versione di X c'è sulla CDN».
---

# Librerie dalla CDN di Enesi

**Regola d'oro:** prima di installare una libreria, chiedi a `cdn.sh` se è su `cdn.ene.si`. Se c'è, si carica da lì; mai leggere `data/cdn-plugins.md` per intero.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. **Cerca**:
   ```bash
   bash scripts/cdn.sh <nome>        # es. swiper, fancybox, jquery-ui
   ```
   - nome esatto (maiuscole indifferenti) → solo quel plugin; altrimenti tutti quelli che contengono il testo (`cdn.sh boot` → bootstrap, bootstrap-icons, bootstrap-select...);
   - risposta: `url: //cdn.ene.si/<plugin>/<versione>/ (ultima)` e l'elenco delle versioni, dalla più vecchia alla più recente;
   - `blocco preventivo: SI` → lo script va bloccato con EPP finché l'utente non accetta i cookie (passo 5);
   - `NON IN CDN` (exit 1) → la libreria non c'è;
   - `cdn.sh` senza argomenti → solo i nomi, per trovare quello giusto (es. `owl-carousel`, non `owl`).
2. **Scegli la versione**: quella che il progetto usa già, se la libreria è già caricata altrove (stessa major); altrimenti l'ultima. Le dipendenze vanno d'accordo (Bootstrap 5 vuole Popper 2, plugin jQuery vogliono jQuery).
3. **Trova il file** dentro la cartella della versione (`jquery.min.js`, `css/swiper.min.css`...): se non lo sai, prendi il nome da un progetto che usa già quella libreria o chiedi; non inventarlo.
4. **Carica**:
   - JS in `partials/base/scripts.blade.php`, fra le librerie, prima dei nostri script (skill `front-scripts`):
     `<script src="//cdn.ene.si/jquery/3.7.0/jquery.min.js"></script>`
   - CSS in `partials/base/head.blade.php`, fra le librerie, prima dei nostri CSS (skill `front-head`).
   - Le librerie dalla CDN non passano da `Version::get()` (non sono asset locali).
5. **Blocco preventivo `SI`**: il blocco **non lo fai tu**, lo fa l'operatore. Carica lo script come al passo 4 e mettigli sopra solo:
   ```blade
   {{-- TODO blocco preventivo: bloccare con EPP fino al consenso cookie (data-epp-*, rules/cookie-consent.md) --}}
   ```
   e dillo all'utente nel riepilogo: «<plugin> va bloccato con EPP, l'ho lasciato con un TODO».
6. **Non c'è sulla CDN** → locale in `assets/main/lib/<libreria>/` (minificata), caricata con `Version::get()` (`rules/assets-structure.md`). Dillo all'utente: potrebbe volerla aggiungere alla CDN.

## No
- Niente lettura completa di `data/cdn-plugins.md`: costa contesto, `cdn.sh` dà già tutto.
- Niente copia in `assets/main/lib/` né CDN pubbliche (jsdelivr, unpkg, cdnjs) per una libreria che è su `cdn.ene.si`.
- Niente URL con una versione che `cdn.sh` non elenca.
- Niente blocco EPP scritto da te (attributi `data-epp-*`) per un plugin con blocco preventivo `SI`: solo il TODO.

La lista si aggiorna a mano in `data/cdn-plugins.md`: una riga `| plugin | versioni | blocco preventivo |` per plugin, versioni dalla più vecchia alla più recente, blocco `SI`/`NO`.
