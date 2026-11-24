#!/usr/bin/env python3
"""DESIGN.md tokens (YAML front matter) -> CSS custom properties, always with the same names.

    colors.primary              -> --color-primary
    colors.brand.500            -> --color-brand-500
    rounded.md / spacing.lg     -> --radius-md / --space-lg
    typography.body-md.fontSize -> --font-body-md-size   (family, size, weight, line-height, letter-spacing)
    motion.fast.duration        -> --motion-fast-duration
    {colors.primary}            -> var(--color-primary)
components are not tokens of :root: they become CSS classes (skill front-design).

Usage:
    design-tokens.py DESIGN.md                  print the :root block
    design-tokens.py DESIGN.md --write main.css write/replace the generated block at the top of main.css
    design-tokens.py --self-test
Standard library only: the front matter is simple nested `key: value` YAML.
"""
import re
import sys

START = "/* design-tokens: start (generato da DESIGN.md con scripts/design-tokens.py, non modificare a mano) */"
END = "/* design-tokens: end */"
GROUPS = {"colors": "color", "rounded": "radius", "spacing": "space", "motion": "motion", "typography": "font"}
FONT_PROPS = {"fontFamily": "family", "fontSize": "size", "fontWeight": "weight", "lineHeight": "line-height",
              "letterSpacing": "letter-spacing", "fontFeature": "feature", "fontVariation": "variation"}


def front_matter(text):
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        sys.exit("DESIGN.md senza front matter YAML (--- ... --- all'inizio)")
    return m.group(1)


def parse(yaml):
    """Nested `key: value` maps by indentation. Lists and anchors are not used by the DESIGN.md tokens."""
    root, stack = {}, [(-1, None)]
    stack[0] = (-1, root)
    for raw in yaml.splitlines():
        line = raw.split(" #")[0].rstrip() if not raw.lstrip().startswith(("'", '"')) else raw.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        key, _, value = line.strip().partition(":")
        key, value = key.strip().strip("'\""), value.strip()
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        if value == "":
            parent[key] = {}
            stack.append((indent, parent[key]))
        else:
            parent[key] = value.strip("'\"")
    return root


def css_value(value):
    return re.sub(r"\{([\w.-]+)\}", lambda m: f"var({ref_name(m.group(1))})", value)


def ref_name(path):
    parts = path.split(".")
    if parts[0] == "typography" and len(parts) == 3:
        return f"--font-{parts[1]}-{FONT_PROPS.get(parts[2], parts[2])}"
    return "--" + "-".join([GROUPS.get(parts[0], parts[0])] + parts[1:])


def flatten(prefix, node, out, typography=False):
    for key, value in node.items():
        if isinstance(value, dict):
            flatten(f"{prefix}-{key}", value, out, typography)
        else:
            name = f"{prefix}-{FONT_PROPS.get(key, key)}" if typography else f"{prefix}-{key}"
            out.append((name, css_value(value)))


def tokens(text):
    data, out = parse(front_matter(text)), []
    for group, short in GROUPS.items():
        if isinstance(data.get(group), dict):
            flatten(f"--{short}", data[group], out, typography=(group == "typography"))
    return out


def block(text):
    lines = [START, ":root {"] + [f"  {n}: {v};" for n, v in tokens(text)] + ["}", END]
    return "\n".join(lines)


def write(css_path, generated):
    css = open(css_path, encoding="utf-8").read()
    if START in css and END in css:
        css = css[:css.index(START)] + generated + css[css.index(END) + len(END):]
    else:
        css = generated + "\n\n" + css
    open(css_path, "w", encoding="utf-8", newline="\n").write(css)


def self_test():
    sample = """---
version: alpha
name: Test
colors:
  primary: "#1A1C1E"
  brand:
    500: '#E63946'
  link: "{colors.brand.500}"
typography:
  body-md:
    fontFamily: Open Sans
    fontSize: 1rem
    lineHeight: 1.5
rounded:
  md: 8px
spacing:
  lg: 2rem
components:
  button:
    backgroundColor: "{colors.primary}"
---
## Overview
"""
    got = dict(tokens(sample))
    assert got["--color-primary"] == "#1A1C1E"
    assert got["--color-brand-500"] == "#E63946"
    assert got["--color-link"] == "var(--color-brand-500)"
    assert got["--font-body-md-family"] == "Open Sans"
    assert got["--font-body-md-line-height"] == "1.5"
    assert got["--radius-md"] == "8px" and got["--space-lg"] == "2rem"
    assert not any(n.startswith("--components") for n in got), "components are classes, not :root tokens"
    assert ref_name("typography.body-md.fontSize") == "--font-body-md-size"
    print("self-test OK")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args == ["--self-test"]:
        self_test()
    elif len(args) == 1:
        print(block(open(args[0], encoding="utf-8").read()))
    elif len(args) == 3 and args[1] == "--write":
        write(args[2], block(open(args[0], encoding="utf-8").read()))
        print(f"OK: token di {args[0]} scritti in {args[2]}")
    else:
        sys.exit(__doc__)
