# Regola: email, il design vive in un posto solo

Le email partono sempre da `private/front/Main/Views/mail/base.blade.php`, ma il **design vero** può vivere in due posti. Prima di toccare una mail capisci quale dei due usa il progetto e lavora **solo lì**.

## Come riconoscerlo

Apri `Views/mail/base.blade.php`:

| Cosa contiene | Il design vive | Esempio |
|---|---|---|
| `@extends('BaseModulePreset::mail.base')` + `@section('content')` | nell'**admin**: `private/master/Foundation/Modules/Base/Views/mail/` (`base.blade.php`, `partials/header`, `partials/footer`), namespace `BaseModulePreset` | cia-web |
| l'HTML completo della mail (`<!DOCTYPE`, `<style>`, tabelle) | nel **front**: `Views/mail/` (`base`, `partials/`, `blocks/`) | motoupgrade |

Se `Views/mail/base.blade.php` non c'è: progetto nuovo, il default è l'admin (crea il `base` che estende `BaseModulePreset::mail.base`). Il design nel front si fa solo se il progetto lo chiede.

## Design nell'admin

```blade
@extends('BaseModulePreset::mail.base')

@section('content')
    {!! $content !!}
@endsection
```

- Header, footer, colori, logo: in `private/master/Foundation/Modules/Base/Views/mail/` (copia del progetto: mai in `vendor/`).
- Il `base` del front resta così: riempie solo `content`.

## Design nel front

```
Views/mail/
├── base.blade.php        HTML completo: <head> con gli <style>, header, contenuto, footer
├── partials/             header.blade.php, footer.blade.php
└── blocks/               un file per tipo di blocco: title, text, button, list, code, two-columns...
```

- Il `base` scorre `$blocks` e include `mail.blocks.<tipo>` per ogni `$block['type']`. Blocco nuovo = file nuovo in `blocks/` + il suo `@include` nel `base` + le sue classi negli `<style>` del `base`.
- Ogni blocco è una riga `<tr><td class="...-block">` della tabella da 600px del `base`.

## Sì
- CSS inline e `<style>` nel `<head>` della mail: i client email ignorano i file `.css` (eccezione di `no-inline.md`).
- Layout a tabelle, larghezza 600px, regole mobile in `@media only screen and (max-width: 480px)`.

## Accessibilità della mail

Vale nel posto dove vive il design (admin o front). Molti lettori di email leggono la mail ad alta voce, e molti client bloccano le immagini: la mail deve reggersi sul testo.

- **`<html lang="{{ app()->getLocale() }}">`**, non `Websites::currentLanguage()` come nel layout del sito: una mail spedita da una coda o da un comando non ha la richiesta da cui `Websites::current()` ricava il website, e il `lang` uscirebbe vuoto; il locale del Mailable (`->locale($user->lang)`) invece vale anche lì. Il `base` delle mail del core ha `lang="it"` fisso: nella copia del progetto (`private/master/Foundation/Modules/Base/Views/mail/base.blade.php`) va sostituito. Per le lingue RTL anche `dir="rtl"` (con le proprietà fisiche girate a mano: nei client email il CSS logico non funziona, `lang-rtl.md`). `<title>` con l'oggetto della mail.
- **Tabelle di impaginazione con `role="presentation"`** (`<table role="presentation" cellpadding="0" cellspacing="0" border="0">`): senza, il lettore di schermo annuncia righe e colonne di ogni tabella. Solo una tabella con dati veri (riepilogo d'ordine) resta senza `role` e ha le sue `<th scope="col">`.
- **`alt` su ogni immagine**: logo = nome del marchio, immagine che porta informazione = il testo che contiene, decorativa = `alt=""`. Mai un'informazione (codice sconto, data, istruzioni) solo dentro un'immagine.
- **Titoli veri** (`<h1>` per il titolo della mail, poi `<h2>`), non `<td>` con il testo grande.
- **Bottoni come link** con testo che dice dove portano («Conferma l'indirizzo email», non «Clicca qui»), area cliccabile almeno 44px di altezza, contrasto AA fra testo e sfondo del bottone (`design-md.md`).
- Testo di almeno 14px (16px per il corpo), `line-height` 1.5, allineato a sinistra (non giustificato); larghezza che regge lo zoom (tabella `width="100%"` con `max-width: 600px`).
- **Versione testo** (`text/plain`) accanto all'HTML quando la mail è importante (conferme, password): in Laravel `->text('mail.<nome>-text')` o il `text` del Mailable.
- Link con l'URL completo nel testo solo per i link di emergenza («Se il bottone non funziona, copia questo indirizzo: ...»).

## No
- Niente design in due posti: se la mail usa `BaseModulePreset`, non aggiungere header/footer o stili nel front, e viceversa.
- Niente modifiche a `vendor/enesisrl/laravel-master-core/.../mail/`: si perdono all'aggiornamento.
- Niente asset dell'utente fuori da `assets/mail/` (immagini, loghi delle email).

Verifica: l'agente apre la mail (anteprima del Mailable o Mailpit) e controlla: immagini spente, si capisce tutto; tabelle di layout con `role="presentation"`; `alt` su ogni `<img>`; un `<h1>`; bottoni con testo chiaro. `scripts/check-views.sh` controlla solo che `Views/mail/` esista.
