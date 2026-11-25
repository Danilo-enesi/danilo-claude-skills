---
name: front-lang-css
description: CSS e HTML del front Master Laravel Enesi adatti alle lingue "difficili" - RTL (arabo, ebraico, persiano, urdu: lang e dir, Bootstrap RTL, proprietà logiche, icone specchiate, tipografia araba), CJK (cinese, giapponese, coreano: zh-Hans/zh-Hant, font di sistema, a capo, enfasi, spazio verticale), testo lungo o alfabeto esteso (tedesco, russo, polacco, filippino...: larghezze flessibili, hyphens, glifi cirillici). Attivala quando il sito ha o sta per avere una di queste lingue e scrivi o modifichi CSS, markup, layout, font o componenti del front: «aggiungiamo l'arabo / il cinese / il tedesco / il russo», «sito in arabo», «RTL», «right to left», «testo che sfonda in tedesco», «font cinese», «layout specchiato». Non serve su siti con sole lingue latine di lunghezza simile all'italiano (es. it/en/es/fr).
---

# CSS per lingue difficili

**Regola d'oro:** il CSS non presume la direzione, la scrittura né la lunghezza del testo. Direzione da `dir`, larghezze che si adattano al testo, e ciò che serve a una sola lingua nel suo file `assets/main/css/lang/<iso_code2>.css`.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## 1. Quali lingue ha il sito

Leggi i `'locale' => '<lang>'` di `private/front/Main/Routes/web.php`, o a runtime `php artisan tinker --execute="echo implode(',', array_keys(Websites::current('enabledFrontLanguages') ?: []));"`. Raggruppa:

| Gruppo | Codici | Regola |
|---|---|---|
| RTL | `ar`, `he`, `fa`, `ur` | `rules/lang-rtl.md` |
| CJK | `zh`, `ja`, `ko` | `rules/lang-cjk.md` |
| testo lungo / alfabeto esteso | `de`, `ru`, `uk`, `pl`, `fi`, `nl`, `fil`/`tl`, `el`, `cs`, `ro`, `tr`... | `rules/lang-long-text.md` |

Nessun gruppo presente → fermati, questa skill non serve. Più gruppi → leggi tutte le regole che servono, non solo la prima.

## 2. Una volta per sito (se mancano)

- **Ogni gruppo**: `lang` completo sull'`<html>` da `locale_code` (`it_IT` → `it-IT`), con il view composer di `rules/lang-rtl.md` sezione HTML. Senza `lang` giusto non funzionano né `hyphens`, né `:lang()`, né la voce del lettore di schermo.
- **RTL**: `dir` dallo stesso composer; `bootstrap.rtl.min.css` al posto di `bootstrap.min.css` in `partials/base/head.blade.php` (skill `front-head`); opzione RTL attivata in ogni libreria JS con una direzione (slider, offcanvas, datepicker).
- **File di lingua**: `assets/main/css/lang/<iso_code2>.css` (`ar.css`, `zh.css`, `tl.css`...), caricato da `partials/base/head.blade.php` dopo `main.css`/`responsive.css` e solo nelle pagine di quella lingua, se il file esiste: lo carica il componente `<x-lang-css />` (regola `head`, sezione "File di lingua"), le regole del file da `css-split`. Ci vanno **solo** le correzioni di quella lingua; `main.css` resta uguale per tutte.
- **Font**: un token per scrittura in `DESIGN.md` (skill `front-design`): font arabo, pila di sistema CJK, font con il subset cirillico/latin-ext. Applicato nel file di lingua.
- **hreflang** con due scritture della stessa lingua (zh semplificato e tradizionale): codice completo (`rules/alternates.md`).

## 3. Ogni volta che scrivi CSS o markup

1. **Proprietà logiche sempre** (`margin-inline-start`, `inset-inline-end`, `text-align: start`, utility `ms-*`/`me-*` di Bootstrap 5), anche se oggi l'RTL non c'è: non costano nulla e l'arabo aggiunto dopo non obbliga a riscrivere il CSS.
2. **Niente larghezze fisse** su testo tradotto (bottoni, tab, menu, badge): `min-width` + `padding`, a capo permesso.
3. **Niente stili tipografici che presumono il latino** senza azzerarli per le lingue che non li reggono: `letter-spacing`, `text-transform`, corsivo per enfasi → li azzera il file di lingua (`lang/ar.css`, `lang/zh.css`).
4. **Ciò che ha una direzione** (icone freccia, animazioni da un lato, `translateX`, sfondi posizionati) → regola gemella con `:dir(rtl)` accanto all'originale.
5. **Testo dentro immagini**: mai; testo vero sopra l'immagine.
6. **Contenuto misto**: `lang` sui frammenti in un'altra lingua (le voci del selettore lingua hanno ognuna il suo `lang`), `<bdi>`/`dir="auto"` su testo dell'utente, `dir="ltr"` su telefono, email, URL, codici.
7. **Numeri e date** formattati per lingua: `Carbon::translatedFormat()`, `Intl.*` nel JS.

## 4. Verifica

Lo fa l'agente, guardando le pagine: nessuno script riconosce un layout che "sembra giusto" in arabo.

- Apri le pagine principali in ogni lingua dei gruppi presenti, a 360px e 1280px, e confrontale con l'italiano: segui la sezione "Verifica" di ogni regola.
- `grep -nE "margin-(left|right)|padding-(left|right)|(^|[^-])(left|right):|text-align: *(left|right)" assets/main/css/*.css` → proprietà fisiche rimaste (con RTL vanno tutte convertite o gemellate con `:dir(rtl)`).
- Lettore di schermo: almeno una pagina in arabo/cinese con NVDA o VoiceOver se il cliente lo richiede; `lang` giusto è il minimo che lo rende possibile.
- Nel riepilogo del lavoro elenca cosa hai controllato e in quali lingue.

## No
- Niente copia di `main.css` per lingua (`main-ar.css`): il file di lingua ha solo le correzioni, e le regole di direzione (proprietà logiche, `:dir(rtl)`) restano in `main.css`, perché valgono per ogni lingua RTL.
- Niente `:lang(xx)` in `main.css`/`responsive.css` per correzioni di una lingua sola: vanno in `lang/<iso_code2>.css`.
- Niente layout girato a mano (`row-reverse`, `order`) per fare l'RTL.
- Niente webfont CJK completi.
- Niente regole di queste lingue applicate a un sito che non le ha: si parte sempre dal punto 1.
