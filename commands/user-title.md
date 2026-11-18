---
description: Rinomina la sessione in <UTENTE>-<nome> (es. /user-title FIX-ESPANGO → DANILO-FIX-ESPANGO)
argument-hint: <nome>
---

The `session-title` hook has already renamed this session; it put the final name in your context as "session-title hook: sesión renombrada a <NAME>". Reply with exactly one line: `Sesión renombrada a <NAME>`. Do nothing else: no tools, no extra text.

If that context line is missing, the hook did not run: reply with one line in Spanish saying the session was NOT renamed because the `session-title` hook is not active, and suggest `/rename <USUARIO>-$ARGUMENTS`.
