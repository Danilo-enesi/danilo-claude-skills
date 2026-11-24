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

## No
- Niente design in due posti: se la mail usa `BaseModulePreset`, non aggiungere header/footer o stili nel front, e viceversa.
- Niente modifiche a `vendor/enesisrl/laravel-master-core/.../mail/`: si perdono all'aggiornamento.
- Niente asset dell'utente fuori da `assets/mail/` (immagini, loghi delle email).

Verifica: a mano. `scripts/check-views.sh` controlla solo che `Views/mail/` esista.
