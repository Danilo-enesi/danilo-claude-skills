# Regola: lingue RTL (arabo, ebraico, persiano, urdu)

Vale quando il website ha fra le lingue front attive `ar`, `he`, `fa` o `ur`. Il layout si specchia: tutto ciò che ha una direzione (margini, allineamenti, icone, slider, tasti freccia) deve seguire `dir`, non essere scritto per sinistra→destra.

## HTML

`lang` e `dir` sull'`<html>`, calcolati una volta in un view composer su `layouts.main` (`shared-data.md`), registrato in `FrontServiceProvider::boot()`:

```php
View::composer(['layouts.main'], function ($view) {
    $lang = Websites::currentLanguage() ?: [];

    $view->with([
        'htmlLang' => str_replace('_', '-', $lang['locale_code'] ?? app()->getLocale()), // it_IT → it-IT
        'htmlDir'  => in_array($lang['iso_code2'] ?? '', ['ar', 'he', 'fa', 'ur'], true) ? 'rtl' : 'ltr',
    ]);
});
```

```blade
<html lang="{{ $htmlLang }}" dir="{{ $htmlDir }}">
```

- Testo dell'utente o di lingua incerta dentro una pagina RTL (nomi, recensioni, titoli importati): `<bdi>` o `dir="auto"`.
- Telefono, email, URL, IBAN, codici prodotto, numeri d'ordine restano sinistra→destra: `dir="ltr"` sull'elemento e sull'`input` (`<input type="email" dir="ltr">`).
- Ordine del DOM = ordine di lettura. Il browser lo inverte da solo con `dir="rtl"`: niente `order`, `flex-direction: row-reverse` o posizionamenti per "girare" il layout.

## Bootstrap

Con `dir="rtl"` si carica `bootstrap.rtl.min.css` **al posto di** `bootstrap.min.css` (stessa versione, su cdn.ene.si c'è):

```blade
<link href="//cdn.ene.si/bootstrap/5.3.3/css/bootstrap{{ $htmlDir === 'rtl' ? '.rtl' : '' }}.min.css" rel="stylesheet">
```

Le utility di Bootstrap 5 sono già logiche (`ms-*`, `me-*`, `ps-*`, `pe-*`, `text-start`, `text-end`, `float-start`) e si girano da sole con il CSS RTL. Le classi di Bootstrap 4 (`ml-*`, `mr-*`, `text-left`) no.

## CSS

| No (fisico) | Sì (logico) |
|---|---|
| `margin-left`, `padding-right` | `margin-inline-start`, `padding-inline-end` |
| `left: 0`, `right: 1rem` | `inset-inline-start: 0`, `inset-inline-end: 1rem` |
| `text-align: left` / `right` | `text-align: start` / `end` |
| `border-left` | `border-inline-start` |
| `border-top-left-radius` | `border-start-start-radius` |
| `float: left` | `float: inline-start` (o la utility `float-start`) |

- Flexbox e Grid seguono `dir` da soli.
- Ciò che resta fisico (una `transform: translateX()`, un'animazione che entra da sinistra, uno sfondo posizionato) si gira con `:dir(rtl)` o `[dir="rtl"]` in `main.css`, accanto alla regola originale.
- Icone **direzionali** (frecce, chevron, "indietro", "avanti", freccia del link "leggi tutto") si specchiano: `[dir="rtl"] .icon-arrow { transform: scaleX(-1); }`. **Non** si specchiano loghi, play/pausa, orologi, telefono, spunte, icone di brand.

## Tipografia araba

- Mai `letter-spacing` sul testo arabo: spezza l'unione fra le lettere. Se il design ne usa uno (titoli, bottoni), azzeralo nel file di lingua `assets/main/css/lang/ar.css`: `.titolo { letter-spacing: 0; }`.
- Niente `text-transform` né corsivo: in arabo non esistono maiuscole né corsivo vero. Enfasi con il peso.
- `line-height` 1.7-2 e corpo un po' più grande del latino: i diacritici chiedono spazio in verticale.
- Font con i glifi arabi (Noto Sans Arabic, IBM Plex Sans Arabic, Cairo, Tajawal), come token di `DESIGN.md` per la lingua, applicato in `assets/main/css/lang/ar.css`. Se è un Google Font passa dal consenso cookie come gli altri (`cookie-consent.md`).
- Niente `text-align: justify`: in arabo allunga i tratti di unione e il testo si legge male.

## Componenti e JS

- Slider e caroselli (Swiper, Slick...), barre di avanzamento, menu laterali (offcanvas), tooltip e datepicker hanno un'opzione RTL: va attivata (Swiper legge `dir="rtl"` dal contenitore; altre librerie vogliono `rtl: true`).
- Tasti freccia in tab, menu e caroselli: in RTL ← va avanti e → torna indietro.
- Numeri e date con `Intl.NumberFormat` / `Intl.DateTimeFormat` nel JS e `Carbon::translatedFormat()` nelle Blade: alcune regioni usano le cifre arabo-orientali, altre quelle occidentali. Mai cifre o formati scritti a mano.

## Email

Le email in una lingua RTL hanno `dir="rtl"` sul contenitore e allineamenti girati (`align="right"` nelle tabelle). Il CSS logico in molti client email non funziona: lì restano le proprietà fisiche, invertite (skill `front-mail`).

## No
- Niente `margin-left`/`right`, `left:`/`right:`, `text-align: left/right` nel CSS del sito: proprietà logiche.
- Niente layout girato a mano con `row-reverse` o `order`.
- Niente `bootstrap.min.css` e `bootstrap.rtl.min.css` caricati insieme.
- Niente icone di brand o di riproduzione specchiate.

Verifica: l'agente apre una pagina in arabo e la confronta con la stessa in italiano: tutto specchiato (menu, colonne, icone direzionali, slider), testo che non tocca i bordi, nessun `letter-spacing`, campi email/telefono sinistra→destra. `grep -nE "margin-(left|right)|padding-(left|right)|(^|[^-])(left|right):|text-align: *(left|right)" assets/main/css/*.css` trova le proprietà fisiche rimaste.
