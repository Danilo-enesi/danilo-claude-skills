# Regola: Version::get() e split debug/produzione

## Sì
- Ogni asset locale passa da `{{ \Master\Facades\Version::get('/assets/...') }}`: il browser non tiene la cache vecchia.
- I nostri CSS e JS si caricano in base all'ambiente:

```blade
@if(config('app.debug'))
  {{-- sviluppo: i file sorgente (beers + main + responsive + moduli) --}}
@else
  {{-- produzione: SEMPRE un unico file minificato --}}
  {{-- /assets/main/css/base.min.css · /assets/main/js/base.min.js --}}
@endif
```

- Le librerie restano fuori dallo split e prima dei nostri file.

## No
- Niente `asset('assets/...')` o `href="/assets/..."` senza `Version::get()`.
- Niente `base.min.*` modificati a mano: si rigenerano.
- Un nostro file nuovo che non entra in `base.min.*` in produzione non esiste: aggiungilo al bundle. Eccezioni: il JS di una pagina `js/pages/<entità>.js`, caricato solo da `pages/<entità>/scripts.blade.php` uguale nei due ambienti (`scripts-loading.md`); i file di lingua `css/lang/<iso_code2>.css`, caricati da `<x-lang-css />` fuori dallo split, uguali nei due ambienti (pochi byte, solo nelle pagine di quella lingua; un bundle per lingua duplicherebbe tutto il CSS e invecchierebbe a ogni modifica di `main.css`).

Verifica: `scripts/check-head.sh`, `scripts/check-scripts.sh`
