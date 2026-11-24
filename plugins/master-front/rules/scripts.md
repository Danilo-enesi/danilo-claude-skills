# Regola: partials/base/scripts.blade.php

Tutto il JavaScript, nostro e delle librerie. **Solo script.**

Ordine:
1. **Primo**: lo `<script>` con `window.front = { route, base_url, lang, google_api_key, id_country_italia }` e le traduzioni dalla cache. È la config di default: copiala dal template.
2. Librerie (CDN o `assets/main/lib/`): sempre caricate, senza split di ambiente.
3. I nostri script, con lo split di ambiente (vedi `assets-versioning`).
4. Il blocco `@if(session()->has('callbacks'))` che esegue `Beers.callbacks.fireList(window.front.callbacks)`.

## No
- Niente librerie dopo i nostri script: le librerie vanno prima.
- Niente markup (es. il bottone torna-su): non è uno script, va nel layout o in un partial.

Verifica: `scripts/check-scripts.sh` · Template: `templates/views/partials/base/scripts.blade.php`
