# Regola: consenso cookie (EPP)

Ogni risorsa di terze parti nasce **bloccata** e si sblocca al consenso.

1. `{!! Dom::renderCookieBanner() !!}` subito dopo `Meta::render()`, prima di ogni risorsa bloccata. Senza `epp_policy_id` sul Website il banner non esce.
2. Google Fonts: **solo** `Meta::googleFonts($url, ...)`, che crea il `<link>` già bloccato (categoria `10003`).
3. Tutto il resto, a mano:

| Cosa | Come |
|---|---|
| script esterno | `data-epp-onconsent` + `src` → `data-epp-src` |
| script inline | `data-epp-onconsent` + `type="text/plain"` |
| `<link>` di terzi | `href` → `data-epp-href` |
| `<iframe>` | `src` → `data-epp-src`, con `src="about:blank"` |
| gruppo di iframe | `data-epp-autolock` sul contenitore |
| categoria | `data-epp-category="10002"` statistiche, `"10003"` esperienza (font, mappe, video) |

4. Google tag: solo se c'è `google_analytics_id` e **non** in debug, loader con categoria `10002` (vedi template di head).

## No
- Niente CSS di `privacy.ene.si`: l'SDK lo inietta da solo.
- Niente reCAPTCHA bloccato: romperebbe i form.

Catalogo completo: `skills/front-cookie-consent/references/epp-cookie-banner.md`. Verifica: `scripts/check-head.sh`
