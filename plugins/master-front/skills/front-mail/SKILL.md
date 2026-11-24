---
name: front-mail
description: Email del Master Laravel Enesi: template, blocchi, header/footer delle mail inviate dal sito. Prima capisce dove vive il design (admin con `BaseModulePreset::mail.base` o front con `Views/mail/` completo) e lavora solo lì. Attivala quando crei o modifichi una email: «template email», «mail di conferma», «blocco della mail», «header/footer della mail», «logo nella mail», «nuovo tipo di blocco email».
---

# Email

**Regola d'oro:** il design della mail vive in un posto solo, admin o front. Prima lo trovi, poi lavori solo lì.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Apri `private/front/Main/Views/mail/base.blade.php` e riconosci il caso (`rules/mail.md`):
   - `@extends('BaseModulePreset::mail.base')` → design nell'**admin**: `private/master/Foundation/Modules/Base/Views/mail/`.
   - HTML completo → design nel **front**: `Views/mail/` (`base`, `partials/`, `blocks/`).
   - non esiste → crea il `base` che estende `BaseModulePreset::mail.base` (default), salvo richiesta contraria.
2. Modifica solo nel posto trovato:
   - admin: header/footer/stili in `private/master/.../mail/`, mai in `vendor/`.
   - front: blocco nuovo = `blocks/<tipo>.blade.php` + `@include` nel `base` + classi negli `<style>` del `base`.
3. Immagini e loghi delle email in `assets/mail/`.
4. CSS inline e `<style>` sono ammessi solo qui (`rules/no-inline.md`).

## No
- Niente header/footer o stili nel front se la mail estende `BaseModulePreset`, e viceversa.
- Niente template email fuori da `Views/mail/`.
