"""Deterministic facts about the repo-deck mod: palette, sections, state atoms, buttons, hotkeys, files.

Usage: python -I inspect.py [mod_dir] [--json] [--check]
mod_dir defaults to the mod this script ships in (three folders up).
--check exits 1 when a consistency rule fails (section colour not in the palette, atom not in the
state contract or the reverse, duplicate or invalid hotkey, missing marketplace entry inside the repo).
"""
import json, re, sys
from pathlib import Path


def read(p):
    return p.read_text(encoding='utf-8') if p.exists() else ''


def buttons(src):
    """Each <Button ...>label</Button>: attrs scanned brace-aware, since onPress arrows hold '>'."""
    out, i = [], 0
    while (i := src.find('<Button', i)) >= 0:
        j, depth, quote = i + 7, 0, ''
        while j < len(src):
            c = src[j]
            if quote:
                quote = '' if c == quote else quote
            elif c in '"\'`':
                quote = c
            elif c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
            elif c == '>' and depth == 0:
                break
            j += 1
        attrs = src[i + 7:j]
        end = src.find('</Button>', j)
        body = src[j + 1:end] if end > 0 else ''
        key = re.search(r'\bkey=(?:"([^"]*)"|\{([^}]*)\})', attrs)
        hot = re.search(r'\bhotkey="([^"]*)"', attrs)
        label = re.sub(r'<[^>]+>', '', body)
        label = re.sub(r'\{[^{}]*\}', lambda m: m.group(0) if "'" in m.group(0) else '{…}', label)
        out.append({
            'key': (key.group(1) or key.group(2)) if key else None,
            'hotkey': hot.group(1) if hot else None,
            'label': ' '.join(label.split()),
            'line': src.count('\n', 0, i) + 1,
        })
        i = j
    return out


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    mod = Path(args[0]) if args else Path(__file__).resolve().parents[3]
    reg, deck, types = (read(mod / 'hooks/register.tsx'), read(mod / 'hooks/deck.tsx'), read(mod / 'types/index.d.ts'))
    manifest = json.loads(read(mod / '.claude-plugin/plugin.json') or '{}')
    assert reg and deck, f'not a repo-deck folder: {mod}'

    tone = dict(re.findall(r"^\s+(\w+): '(#[0-9a-fA-F]{6})',", deck.split('as const')[0], re.M))
    sections = [dict(zip(('kind', 'title', 'color'), m))
                for m in re.findall(r"\{ kind: '(\w+)', title: '([^']+)', color: '(\w+)' \}", reg)]
    atoms = [dict(zip(('key', 'shape'), m)) for m in re.findall(r"key: '(\w+)' \} as const, .*?\{ shape: '([^']+)' \}", reg)]
    block = re.search(r"'repo-deck': \{(.*?)\n    \}", types, re.S)
    declared = re.findall(r'(\w+): Shaped<', block.group(1)) if block else []
    btns = buttons(reg)
    usage = {name: len(re.findall(rf"tone\.{name}\b|color: '{name}'|color=\"{name}\"", reg)) for name in tone}
    commands = re.findall(r"command\.register\(\{ name: '([^']+)'", reg)
    pane = re.search(r"const PANE = '([^']+)'", reg)
    files = {str(p.relative_to(mod)).replace('\\', '/'): read(p).count('\n')
             for p in sorted(mod.rglob('*')) if p.is_file() and '.claude-plugin/types' not in p.as_posix()}

    market = mod.parents[1] / '.claude-plugin/marketplace.json'
    entry = None
    if market.exists():
        entry = next((p for p in json.loads(read(market)).get('plugins', []) if p.get('source') == './mods/repo-deck'), None)

    problems = []
    problems += [f"section {s['title']} uses colour '{s['color']}' missing from tone" for s in sections if s['color'] not in tone]
    problems += [f"atom '{a['key']}' not declared in types/index.d.ts" for a in atoms if a['key'] not in declared]
    problems += [f"state '{d}' declared but no atom uses it" for d in declared if d not in {a['key'] for a in atoms}]
    hot = [b['hotkey'] for b in btns if b['hotkey']]
    problems += [f"hotkey '{h}' used {hot.count(h)} times" for h in sorted(set(hot)) if hot.count(h) > 1]
    problems += [f"hotkey '{h}' is not one digit or lowercase letter" for h in hot if not re.fullmatch(r'[0-9a-z]', h)]
    if market.exists() and not entry:
        problems.append('no marketplace.json entry with source ./mods/repo-deck')

    facts = {
        'mod': str(mod), 'version': manifest.get('version'), 'commands': commands, 'pane': pane.group(1) if pane else None,
        'palette': [{'name': n, 'hex': h, 'uses_in_register': usage[n]} for n, h in tone.items()],
        'sections': sections, 'atoms': atoms, 'declared_state': declared, 'buttons': btns,
        'free_hotkeys': [c for c in 'abcdefghijklmnopqrstuvwxyz' if c not in hot],
        'marketplace_entry': entry, 'files': files, 'problems': problems,
    }
    if '--json' in sys.argv:
        print(json.dumps(facts, indent=1, ensure_ascii=False))
    else:
        print(f"repo-deck v{facts['version']} · /{', /'.join(commands)} · pane {facts['pane']}")
        print('palette:  ' + '  '.join(f"{p['name']} {p['hex']} ({p['uses_in_register']})" for p in facts['palette']))
        print('sections: ' + '  '.join(f"{s['title']}={s['color']}" for s in sections))
        print('atoms:    ' + '  '.join(f"{a['key']}@{a['shape']}" for a in atoms))
        for b in btns:
            print(f"button    l{b['line']:<4} key={b['key']}  hotkey={b['hotkey'] or '-'}  {b['label']}")
        print('free hotkeys: ' + ''.join(facts['free_hotkeys']))
        print('files:    ' + '  '.join(f'{k}({v})' for k, v in files.items()))
        print('problems: ' + ('none' if not problems else '\n  - ' + '\n  - '.join(problems)))
    if '--check' in sys.argv and problems:
        sys.exit(1)


if __name__ == '__main__':
    main()
