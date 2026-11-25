# Regola: lingue CJK (cinese, giapponese, coreano)

Vale quando il website ha fra le lingue front attive `zh`, `ja` o `ko`. La direzione non cambia: cambiano font, a capo, enfasi e spazio verticale.

## HTML

- `lang` completo sull'`<html>` (composer di `lang-rtl.md`, vale anche qui). Per il cinese conta la **scrittura**, non solo la regione: `zh-Hans` (semplificato: Cina, Singapore) e `zh-Hant` (tradizionale: Taiwan, Hong Kong) sono glifi diversi e i lettori di schermo cambiano voce. Se `locale_code` è `zh_CN` / `zh_TW`, va bene `zh-CN` / `zh-TW`; con entrambe le scritture sul sito, `hreflang` deve distinguerle (`alternates.md`: la chiave è il codice completo, non `zh`).
- Niente testo dentro le immagini (banner, titoli disegnati): non si traduce, non si legge, non si cerca.

## Font

I font CJK pesano diversi MB: **niente webfont completi**. Pila di font di sistema per lingua, come token di `DESIGN.md`, nel file di lingua (`assets/main/css/lang/zh.css`, `ja.css`, `ko.css`; regola `css-split`). Dentro `zh.css` `:lang()` serve ancora, per distinguere semplificato e tradizionale:

```css
:lang(zh-Hans), :lang(zh-CN) { font-family: "PingFang SC", "Microsoft YaHei", "Noto Sans SC", sans-serif; }
:lang(zh-Hant), :lang(zh-TW) { font-family: "PingFang TC", "Microsoft JhengHei", "Noto Sans TC", sans-serif; }
:lang(ja) { font-family: "Hiragino Sans", "Yu Gothic", "Noto Sans JP", sans-serif; }
:lang(ko) { font-family: "Apple SD Gothic Neo", "Malgun Gothic", "Noto Sans KR", sans-serif; }
```

Se il design impone un font CJK di marca, solo con un subset (`unicode-range` o il subset di Google Fonts) e dietro il consenso cookie.

## Testo

- `line-height` 1.6-1.8 e corpo minimo 14-16px: sotto, i tratti dei caratteri si impastano.
- **A capo**: non ci sono spazi fra le parole, il browser va a capo fra i caratteri. `line-break: strict` evita la punteggiatura a inizio riga; `overflow-wrap: anywhere` dove un URL o una parola latina lunga sfonda il contenitore. Per il cinese **niente** `word-break: keep-all` (righe che non vanno più a capo); per il coreano invece sì, perché separa le parole con spazi.
- **Enfasi**: niente corsivo né sottolineato (il sottolineato è il link). Grassetto o `text-emphasis: filled dot`.
- Niente `text-transform: uppercase` e niente `letter-spacing` ereditato dal design latino: azzeralo nel file di lingua.
- Il cinese occupa **meno larghezza** e serve più altezza: titoli e bottoni non devono avere altezze fisse né contare su un numero di righe.
- La meta description: `Meta` taglia a 160 caratteri, ma in cinese 160 caratteri sono il doppio della larghezza che Google mostra: scrivile di 70-80 caratteri.

## No
- Niente webfont CJK completi.
- Niente corsivo o sottolineato per enfatizzare.
- Niente `word-break: keep-all` sul cinese e sul giapponese.
- Niente `lang="zh"` se il sito ha sia semplificato che tradizionale.

Verifica: l'agente apre una pagina in cinese: font di sistema (nessun font CJK scaricato nella scheda Network), nessuna parola latina o URL che sfonda, punteggiatura mai a inizio riga, niente corsivi.
