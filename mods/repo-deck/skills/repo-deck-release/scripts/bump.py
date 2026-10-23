"""Bump the repo-deck version in .claude-plugin/plugin.json and print old -> new.

Usage: python -I bump.py patch|minor|major [mod_dir]
mod_dir defaults to the mod this script ships in (three folders up).
"""
import json, re, sys
from pathlib import Path


def bumped(version, part):
    m = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)', version)
    assert m, f'not a x.y.z version: {version}'
    major, minor, patch = map(int, m.groups())
    if part == 'major':
        return f'{major + 1}.0.0'
    if part == 'minor':
        return f'{major}.{minor + 1}.0'
    return f'{major}.{minor}.{patch + 1}'


def main():
    assert bumped('0.2.9', 'patch') == '0.2.10' and bumped('0.2.9', 'minor') == '0.3.0' and bumped('1.4.2', 'major') == '2.0.0'
    part = sys.argv[1] if len(sys.argv) > 1 else ''
    assert part in ('patch', 'minor', 'major'), 'usage: bump.py patch|minor|major [mod_dir]'
    mod = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(__file__).resolve().parents[3]
    path = mod / '.claude-plugin/plugin.json'
    text = path.read_text(encoding='utf-8')
    old = json.loads(text)['version']
    new = bumped(old, part)
    # edit the one field in place so the rest of the file keeps its layout
    path.write_text(text.replace(f'"version": "{old}"', f'"version": "{new}"', 1), encoding='utf-8')
    assert json.loads(path.read_text(encoding='utf-8'))['version'] == new
    print(f'{old} -> {new}')


if __name__ == '__main__':
    main()
