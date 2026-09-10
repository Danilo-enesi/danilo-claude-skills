# Riferimento — Cookie Banner EPP (privacy.ene.si)

Sintesi della documentazione ufficiale Enesi (Academy, doc `cookie-banner`), ridotta a ciò che serve
lato front dei progetti Master Laravel Enesi. Nei progetti Master lo script di installazione lo genera
`Dom::renderCookieBanner()`: **non incollarlo a mano**.

## Installazione

```html
<script type="text/javascript" src="//privacy.ene.si/api/js?key=[KEY]&uid=[UID]&ln=[LANG]"></script>
```

* `KEY` — api key del cliente (`Websites::current('ene_api_key')`)
* `UID` — codice progetto (`Websites::current('epp_policy_id')`)
* `LANG` — `ita, eng, spa, fra, deu, por, tur, rus, ukr` (`Websites::currentLanguage('iso_code3')`)

Note operative:

* Il banner appare **solo** se la funzionalità è attiva da backoffice per quel progetto.
* L'SDK inietta da sé il proprio CSS: **non** includere `//privacy.ene.si/api/css`.
* Imposta da sé il **Google Consent Mode v2**, ma solo se non trova già un comando `consent` nel `dataLayer`.
* Gli esempi con `$()` usano jQuery a scopo dimostrativo: l'SDK funziona anche senza jQuery.

## Pulsanti (attributi `data-epp`)

| Attributo                                                  | Effetto                                    |
| ---------------------------------------------------------- | ------------------------------------------ |
| `data-epp="accept"`                                        | accetta tutti i cookie                     |
| `data-epp="decline"`                                       | rifiuta tutti i cookie                     |
| `data-epp="policy"`                                        | apre la Privacy Policy in popup            |
| `data-epp="cookie"`                                        | apre la Cookie Policy in popup             |
| `data-epp="cookie-preferences"`                            | riapre il pannello preferenze              |
| `data-epp="consent-information"` + `data-epp-pid="[PID]"`  | apre un'informativa di consenso            |
| `data-epp="accept-category"` + `data-epp-category="[PID]"` | accetta una singola categoria              |

`accept-category` si attiva **solo dopo** l'accettazione del banner.

Link a pagina esterna (alternativa al popup):

```html
<a href="https://privacy.ene.si/api/policy-full/?uid=[UID]&ln=[LANG]" target="_blank">Privacy Policy</a>
<a href="https://privacy.ene.si/api/cookie-full/?uid=[UID]&ln=[LANG]" target="_blank">Cookie Policy</a>
```

## Blocco preventivo

### Script

```html
<!-- esterno -->
<script data-epp-onconsent data-epp-src="[SRC]"></script>
<script data-epp-onconsent data-epp-category="[PID]" data-epp-src="[SRC]"></script>

<!-- inline: serve un type NON eseguibile -->
<script data-epp-onconsent type="text/plain"> … </script>
<script data-epp-onconsent data-epp-category="[PID]" type="text/plain"> … </script>
```

### Iframe

```html
<iframe data-epp-src="https://www.youtube.com/embed/…" src="about:blank"></iframe>
<iframe data-epp-src="https://www.youtube.com/embed/…" data-epp-category="[PID]" src="about:blank"></iframe>

<!-- gruppo: autolock sul contenitore, gli iframe interni restano con src normale -->
<div data-epp-autolock data-epp-category="[PID]">
    <iframe src="https://www.youtube.com/embed/…"></iframe>
</div>
```

### `<link>` (Google Fonts, CSS di terze parti)

```html
<link data-epp-category="10003" data-epp-href="https://fonts.googleapis.com/css2?family=Open+Sans&display=swap" rel="stylesheet">
```

Nei progetti Master questo lo genera `Meta::googleFonts($url)`.

## API JS

```js
EPP.onAccept(fn);                    // callback all'accettazione
EPP.onAccept(fn, '[PID]');           // callback al consenso di una categoria
EPP.loadScript(src, fn, '[PID]');    // carica un file js al consenso + callback
EPP.isAllowedCategory('[PID]');      // => bool
EPP.allowCategory('[PID]');          // abilita una categoria (azione esplicita dell'utente)
```

Va nel bundle JS del progetto (`template/assets/js/`), non inline nelle Blade.

## Categorie (PID) usate nei progetti

| PID     | Categoria                                              |
| ------- | ------------------------------------------------------ |
| `10002` | Statistiche / analytics (GA4, GTM)                     |
| `10003` | Miglioramento dell'esperienza (font, mappe, embed)     |

Il catalogo completo delle categorie di un progetto è nel backoffice privacy del cliente:
in dubbio, chiedere invece di inventare un PID.

## Integrazione policy server-side

```
GET https://privacy.ene.si/api/policy?uid=[UID]&ln=[LANG]
GET https://privacy.ene.si/api/cookie?uid=[UID]&ln=[LANG]
```

Stampare il risultato in una pagina dedicata (alternativa ai popup).

## Eccezioni note

* **reCAPTCHA**: di norma non si blocca, per non interferire con validazione e invio dei form.
* Un iframe con `data-epp-src` **senza** `src="about:blank"` può comunque generare una richiesta.
