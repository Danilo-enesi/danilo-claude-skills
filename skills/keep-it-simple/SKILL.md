---
name: keep-it-simple
description: Criterio per i commenti nel codice — quando scriverli, quanto devono essere lunghi, e cosa devono contenere. Attivala quando scrivi o modifichi codice e stai per aggiungere un commento, o quando rivedi commenti esistenti in un file. Regola d'oro — l'utente sa leggere il codice, un commento serve solo dove il codice da solo non basta: mai una cronologia di modifiche, sempre lo stato attuale o il perché di una decisione.
---

# Skill: Keep It Simple — disciplina dei commenti

## Regola d'oro

Il default è **nessun commento**. Codice ben scritto (nomi chiari, funzioni piccole) si spiega da solo. Un commento si aggiunge **solo** quando il codice, da solo, lascerebbe un dubbio reale a chi legge — non per "essere gentili" col lettore. L'utente non è stupido: sa leggere e interpretare codice.

## Quando un commento è giustificato (solo nelle parti crucialli)

- Un vincolo nascosto o non ovvio dal codice stesso (un limite esterno, un ordine di esecuzione obbligato).
- Il **perché** di una decisione non ovvia — un'alternativa più semplice esisteva ma è stata scartata per un motivo che il codice da solo non mostra.
- Un workaround per un bug/limite specifico di una libreria/API esterna.
- Un comportamento che sorprenderebbe chi legge per la prima volta (edge case non intuitivo).

Fuori da questi casi: non commentare.

## Quando un commento NON va scritto

- ❌ Spiega **cosa** fa il codice quando nomi/struttura già lo dicono (`// aggiungo 1 al contatore` sopra `contatore++`).
- ❌ Riferisce il task/fix/issue corrente ("aggiunto per il flusso di checkout", "fix per il bug #123", "vedi PR #45") — appartiene al messaggio di commit, non al codice: marcisce nel tempo.
- ❌ È una **cronologia di modifiche** ("modificato il 12/03 da X", "rimosso perché...", codice vecchio lasciato commentato "nel dubbio") — la storia la tiene git, non i commenti.
- ❌ Ripete in prosa il nome della funzione/variabile.
- ❌ Blocco multi-paragrafo o docstring lunga quando basterebbe una riga — o nessuna.

## Forma

- Massimo 1-2 righe. Se serve più spazio per spiegare, probabilmente il codice va semplificato, non commentato di più.
- Riflette **solo** lo stato attuale del codice o una decisione presa e il suo perché — mai un "prima era così, ora è così" o un racconto del processo.
- Se togliendo il commento il lettore capirebbe comunque, il commento non serve: toglilo.

## Checklist rapida prima di scrivere un commento

1. Il codice da solo (con nomi migliori) risolverebbe il dubbio? → non commentare, rinomina.
2. È il **perché**, non il **cosa**? → prosegui, altrimenti fermati.
3. È una parte davvero cruciale (vincolo, workaround, edge case)? → prosegui, altrimenti fermati.
4. Sta in 1-2 righe? → scrivilo. Se no, accorcialo o semplifica il codice.
5. Fra un anno, senza il contesto della task corrente, sarà ancora vero? → se no, non è un commento valido: è una nota di processo, non di codice.
