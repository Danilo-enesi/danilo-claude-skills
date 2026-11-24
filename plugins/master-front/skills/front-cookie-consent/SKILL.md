---
name: front-cookie-consent
description: Blocco preventivo delle risorse di terze parti nel front Master Laravel Enesi con il cookie banner EPP (privacy.ene.si): Dom::renderCookieBanner(), Meta::googleFonts(), attributi data-epp-* su script, iframe e link, categorie 10002/10003, Google tag. Attivala quando aggiungi qualcosa di terze parti: «Google Fonts», «Google Analytics / gtag», «mappa Google/Leaflet», «video YouTube/Vimeo», «iframe», «pixel», «cookie banner», «EPP», «il banner non si vede».
---

# Consenso cookie

**Regola d'oro:** ogni risorsa di terze parti nasce **bloccata**. Includerla "normalmente" è un bug di compliance.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Il banner c'è? `{!! Dom::renderCookieBanner() !!}` in head, subito dopo `Meta::render()`. Se non si vede: `epp_policy_id` vuoto sul Website.
2. È un Google Font? `Meta::googleFonts($url)`. Fine.
3. Altrimenti blocca a mano con la tabella di `rules/cookie-consent.md` (`data-epp-src`, `data-epp-onconsent`, `data-epp-autolock`).
4. Metti la categoria: `10002` statistiche, `10003` esperienza (mappe, video, font).
5. Pulsanti e API JS (`data-epp="policy"`, `EPP.onAccept`...): `references/epp-cookie-banner.md`.
6. Verifica: `bash scripts/check-head.sh <root>`.

## No
- Niente `src`/`href` diretto a un servizio di terzi.
- Niente reCAPTCHA bloccato.
