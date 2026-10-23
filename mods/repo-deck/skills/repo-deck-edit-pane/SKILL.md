---
name: repo-deck-edit-pane
author: Danilo-enesi
description: Change what the repo-deck pane draws or does - a card, a row, the header/legend/summary, a label, a new or changed button and its action - in hooks/register.tsx (and hooks/deck.tsx for shared pieces). Use for requests like "add a button to the detail card", "rename USA NELLA CHAT", "hide X when empty", "move Y next to the title", "make Z clickable". Does not change what is scanned (repo-deck-edit-scan) and does not release.
---

# repo-deck-edit-pane

**Rule:** the smallest edit in `hooks/register.tsx`; touch `hooks/deck.tsx` only when the piece is shared by every card.

## Steps

1. Run `repo-deck-inspect`; read `repo-deck-style` if the change is visual.
2. Find the spot:
   - list cards: the `SECTIONS.map(...)` block; card order/colour/title: the `SECTIONS` array;
   - detail card: the `{current ? (<Card ...` block; its buttons are the row Box with `marginTop={1}`;
   - header/legend: `<Header ...>`; summary: the last Box with `borderDimColor`.
3. Edit. Element rules (refused trees skip the whole render):
   - a `Button` holds only strings and `Text`; every Button in a list has its own `key`;
   - `hotkey` = one digit or lowercase letter not already used (`free hotkeys` from inspect);
   - actions: write in the prompt `$.prompt.fill({ text })`; send as a turn `$.prompt.submit({ text })`; run a slash command `$.command.run({ command, args })`; message `$.ui.toast(text)`; always `void` or `.catch` the promise;
   - new per-entry text the action needs: a small exported pure function (like `askText`) plus a test.
4. New state: `atom({ plugin: 'repo-deck', key } as const, initial, { shape: '<key>-1' })` and the same key in `types/index.d.ts`.
5. Run `repo-deck-check`.

## Notes

- Elements come from `$.ui.resolve(e)`; there are no HTML tags and no DOM.
- Size rows to `e.props.bodyColumns`, never to a fixed width.
- A command name must not clash with a built-in (`/plugins` is refused because of `/plugin`).
