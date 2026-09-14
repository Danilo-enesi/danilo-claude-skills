---
name: master-page-content
author: Danilo-enesi
description: Sistema di blocchi di contenuto (`Contents` field, `page_contents`/`blog_contents`/`project_contents`...) del Master Laravel Enesi. Attivala quando si parla di blocco/block/content block, `page_contents`, aggiungere/estendere un tipo di blocco, installare i blocchi su un modulo nuovo (es. Products), `BlockRenderer`, componente blocco frontend, o `moduleName`/`viewsModuleName` del field `Contents`. Ricorda: NON sono componenti statici — contenuto, ordine, tipo e formato arrivano dalle righe DB (`<entity>_contents.data` JSON) inserite dall'admin.
---

# Skill: Sistema blocchi di contenuto (`Contents`)

## Regola mentale — i blocchi sono DB-driven, NON statici

Un model con blocchi (Page, Blog, Project, ...) non ha un corpo fisso. Il suo contenuto è una **lista ordinata di righe DB** (`<entity>_contents`), ognuna con un `type` e un payload JSON libero (`data`). L'admin costruisce, ordina e riempie questi blocchi dal pannello Contenuti; il frontend legge le righe e mappa ogni `type` a un componente che è un **puro renderer**.

> Se stai per hardcodare testo, ordine, o assumere che un tipo di blocco esista solo su un modulo, ti stai sbagliando: tutto arriva da `getBlockData()` / `getContentMedia()`, ed esiste su qualsiasi modulo che abbia installato il sistema (vedi sotto).

## Quale file satellite ti serve

Il sistema ha **4 capa** (Field/toolbar → editor widget admin → dispatch AJAX → persistenza → lettura frontend) e questa skill le separa in 4 file, letti **solo** quando servono:

| Hai bisogno di... | Leggi |
|---|---|
| Capire l'architettura interna, chi chiama cosa, `moduleName` vs `viewsModuleName`, il gotcha `page_contents()`/`getBlocksAttribute()` | **`references/package-internals.md`** — leggilo SEMPRE prima degli altri tre, sono il contesto condiviso |
| Aggiungere i blocchi a un modulo che non li ha (es. Products, Services, un CRUD di progetto) | **`references/install-non-conventional.md`** |
| Capire il catalogo dei tipi esistenti, estendere un tipo (es. aggiungere un campo a `text`), aggiungere un tipo di blocco nuovo | **`references/conventional-blocks.md`** |
| Scrivere/adattare il rendering pubblico (componente + Blade) di un blocco | **`references/frontend-convention.md`** — è una convenzione minima di riferimento, non l'unico modo valido: se il progetto ha già un frontend con blocchi (sidebar, grouping, design system proprio), rispetta quello e usa questo file solo per i tipi non ancora implementati |

## `type` DB — i soli 6 valori standard + 1 custom

`title`, `text`, `article`, `gallery`, `attachments`, `video_embed` sono fissi nel package (catalogo completo in `conventional-blocks.md`). `image_full` è l'unico tipo custom già presente in tutti i moduli esistenti (Pages/Blog/Projects) — aggiunto via il meccanismo `getCustomContents()` descritto in `conventional-blocks.md`, non nel package.

## Prima domanda da farti quando ti attivano su questo tema

**Il modulo di cui si parla ha già il sistema Contents installato?** (verifica: il suo model principale ha `$contentClass`/`$content_foreign_key` dichiarati — via eredità da `Page` o via il trait `HasContentBlocks`, vedi `install-non-conventional.md` — e c'è una tabella `<entity>_contents`?)
- **Sì** → probabilmente stai lavorando su un tipo di blocco (estenderlo/aggiungerne uno) o sul frontend → `conventional-blocks.md` / `frontend-convention.md`.
- **No** → stai installando il sistema da zero su un modulo → `install-non-conventional.md`. Non improvvisare copiando solo pezzi: la procedura ha un passo (il dispatch `newContent()`) che fallisce in silenzio se saltato.

## Errori trasversali da evitare

- ❌ Trattare un blocco come componente statico con testo/ordine fissi. ✅ Tutto da `getBlockData()`/`getContentMedia()`.
- ❌ Modificare i file sotto `vendor/enesisrl/...`. ✅ Ogni fix di package va nel repo `laravel-master-dev` e tirato via Composer; a livello progetto usa gli override in `Master\Foundation\Form\...`.
- ❌ Cercare i media dentro `<entity>_contents.data`. ✅ Vivono nelle righe Spatie `media`, collezione `content<Tipo>__<media_id>` (`media_id` è l'unica cosa salvata in `data`).
- ❌ Salvare blocchi con `draft=1` come "live". ✅ Il frontend mostra solo `draft=0`; `draft=1` è la bozza pre-salvataggio creata dal dispatch AJAX prima del submit del form.
- ❌ Assumere che il nome del metodo relazione (`page_contents()`) o dell'accessor (`getBlocksAttribute` → `->blocks`) sia configurabile o rinominabile per modulo. Non lo è — vedi `package-internals.md`.
