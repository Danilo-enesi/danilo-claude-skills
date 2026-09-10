---
name: commit-to-main
description: Come creare commit Git in questo flusso di lavoro — sempre diretti sul branch corrente (main/master, mai una branch feature o una PR), sempre a livello di file intero (mai frammentare un file fra più commit o usare `git add -p`), messaggio di commit in italiano e conciso, raggruppando i file per funzionalità in commit distinti quando cambiano per motivi diversi. Attivala quando senti «fai il commit», «committa queste modifiche», «crea i commit», «salva il lavoro su git», o quando un task di codice va concluso con un commit. Al termine restituisce SEMPRE una tabella file→motivo, mai un semplice "fatto".
---

# Skill: Commit diretti su main

## Regola d'oro

Ogni commit va **diretto sul branch corrente** (`main`/`master`) — mai creare una branch feature, mai aprire una PR: usa il repo così com'è. Ogni commit contiene **file interi**: mai uno spezzone di un file in un commit e il resto in un altro (niente `git add -p`, niente stage parziale). Se più file cambiano per **motivi diversi**, dividili in **commit distinti raggruppati per funzionalità** — ma un singolo file resta sempre intero dentro un solo commit.

## Ambito — per default, TUTTO ciò che mostra `git status`

Il perimetro di default non è "i file toccati in questa sessione": è **tutto** ciò che `git status` mostra come modificato/nuovo/eliminato nel working tree, comprese modifiche fatte **prima o fuori** da questa conversazione (da un editor, da un altro strumento, da una sessione precedente). Non filtrare implicitamente ai soli file che ricordi di aver modificato tu — `git status` è la fonte di verità, non la tua memoria della sessione. L'unica esclusione è il §Segreti qui sotto.

## Procedura

1. `git status` per vedere lo stato reale e completo — mai `git add -A`/`git add .` in un colpo solo: elenca esplicitamente i file per nome quando stagei (per rispettare il raggruppamento e il divieto di stage parziale), ma l'insieme totale dei file stageati fra tutti i commit deve coprire **tutto** quello che `git status` riporta, salvo segreti (sotto).
2. Se compare un file sospetto (`.env`, credenziali, chiavi, token) — leggine il contenuto prima di stageare. Se contiene segreti: avvisa l'utente, **non committarlo**, ed esplicitalo come eccezione nella tabella finale (colonna Motivo: "escluso, contiene segreti").
3. **Raggruppa** i file modificati/nuovi/eliminati per motivo logico (es. "nuova skill X", "fix bug Y", "aggiorna doc Z"). Un gruppo coerente = un commit.
4. Per ogni gruppo: `git add <file1> <file2> ...` elencando i file per nome — mai `-p`, mai un path che stagea solo parte di un file.
5. Messaggio di commit **in italiano, conciso**: un soggetto imperativo breve (indicativamente sotto i 70 caratteri); un corpo solo se aggiunge una motivazione reale ("perché", non "cosa" — il diff mostra già cosa). Niente elenco di file nel messaggio. Usa un HEREDOC per evitare problemi di escaping.
6. Ripeti il passo 4-5 per ogni gruppo — è normale creare **più commit** in una sola esecuzione.
7. Dopo l'ultimo commit: push diretto su `origin/<branch-corrente>`. Se il remoto ha commit non presenti in locale, fai prima pull/rebase — mai sovrascrivere la storia altrui. Mai `--force` salvo richiesta esplicita dell'utente.
8. Se le istruzioni di sistema della sessione richiedono una riga di attribuzione (es. `Co-Authored-By: ...`), aggiungila in fondo a ogni messaggio di commit.

## Cosa NON fare

- ❌ Creare una branch o una Pull Request — questa skill è per commit diretti sul branch corrente.
- ❌ `git add -A` / `git add .` senza aver prima controllato cosa include.
- ❌ Frammentare un file fra due commit (`git add -p`, hunk parziali, `git add` su un file già in parte staged con modifiche successive non incluse).
- ❌ Messaggio di commit in inglese, prolisso, o che elenca semplicemente i file toccati.
- ❌ `--no-verify`, `--no-gpg-sign`, `push --force` senza richiesta esplicita.
- ❌ Committare un file con segreti/credenziali senza prima avvisare l'utente.

## Output finale — SEMPRE una tabella

Al termine di tutti i commit di questa esecuzione (prima di considerare il task concluso), produci **sempre** questa tabella come output — mai un semplice "fatto" o "ho committato tutto":

| File | Motivo |
|---|---|
| `path/al/file1.ext` | breve motivo del cambiamento |
| `path/al/file2.ext` | breve motivo del cambiamento |

Una riga per **ogni file toccato** (aggiunto, modificato o eliminato) in **qualsiasi** commit creato in questa esecuzione, anche se sono finiti in commit diversi. Il "motivo" è una frase breve e concreta — non il messaggio di commit letterale, ma il perché di quel singolo file.
