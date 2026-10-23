# SPEC — migrazione PHP <PHP_PROD> → <PHP_TO>

Fonte: analisi approvata dall'utente. Si cambia solo ciò che **rompe** nel PHP nuovo. Il core (Master 7) non si aggiorna; le librerie di terzi si sostituiscono intere.
Ogni riga ha un test. Prima di migrare **tutti** devono fallire (`run-tests.sh --static --expect-red`).

| ID | Atteso dopo la migrazione | Dove | Come | Test |
|---|---|---|---|---|
| C1-C6 | core Master 7 compatibile | vedi `patches.php` | patch minime | checks C1-C6 |
| P… | (punti del progetto trovati nell'analisi) | | | checks P… |
| L… | (una riga per libreria di `libs.lock`) | | sostituzione intera | checks L… + smoke |
| G1 | tutto il sito compila (tranne `lint-ignore.txt`) | — | — | `lint.sh to` |
| A1 | nessuna chiamata con meno argomenti dei richiesti (ArgumentCountError da 7.1) | tutto il progetto | default `null` sul parametro | `scan-argcount.php` |
| A2 | nessuna costante senza fallback, definizione o valore in tutte le lingue (Error da 8.0) | tutto il progetto | traduzione in Linguaggi, o `defined() ? X : ''` per le costanti di config | `scan-undefconst.php` |
| R1 | stessi stati HTTP di prima, PDF validi, nessun Fatal | front | — | `run-tests.sh --smoke` |
| R2 | admin: nessun Fatal nei moduli | admin | — | `smoke.sh --admin-cookie` + prove manuali |

## Da cercare nell'analisi (oltre al lint)
Cambi 7.0→7.4 e 7.4→8.x che il lint non vede: argomenti mancanti (A1), costanti non definite (A2), `count()/in_array()/implode()/array_filter()/max()` su `null` o array vuoto, `call_user_func_array` con chiavi stringa, parametri per riferimento su `null->prop`, `constant()` su costanti assenti, `trim(array)`, divisione per zero, `ReflectionParameter::getClass()`, proprietà dinamiche nei PDF, API cambiate nelle librerie aggiornate (es. tcpdf 6: `TCPDF_FONTS::addTTFfont`).

## Differenze rispetto all'analisi (approvate)
-

## Fuori ambito
Deprecation che non rompono, refactoring, DB, aggiornamento del core, errori che esistono solo in LOCAL (Windows), funzioni sacrificabili.
