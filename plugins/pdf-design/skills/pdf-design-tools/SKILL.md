---
name: pdf-design-tools
author: Danilo-enesi
description: Check and install the tools every pdf-design skill needs (Python 3.9+, PyMuPDF, Pillow, a headless Edge/Chrome). Use it first, before any other pdf-design skill, or when a pdf-design script fails with ImportError / "No module named". Does nothing else.
---

# pdf-design-tools

**Rule:** no tools, no work. Run the check before anything else.

## Steps

1. Run the check:
   ```
   python -I scripts/check_tools.py
   ```
2. If a package is `MISSING`, show the user the printed `install with:` command and ask before running:
   ```
   python -I scripts/check_tools.py --install
   ```
   It installs into the active venv, else with `pip --user`. Never root, never global.
3. If it says the Python is managed by the OS (PEP 668), do not force it: follow the printed private-venv commands and use that venv's `python` for every pdf-design script.
4. A missing browser only blocks `html-visual-diff`. Tell the user; do not install browsers yourself.

## What each tool is for

| Tool | Used by | Why |
|---|---|---|
| PyMuPDF (`pymupdf`) | extract, fonts, sections, svg-to-png | reads PDFs and renders PDF/SVG to PNG; no Poppler or Cairo needed |
| Pillow | html-visual-diff | pixel diff between screenshot and reference |
| Edge / Chrome headless | html-visual-diff | screenshots of HTML pages |

## Rules

- Never use `sudo`, `--break-system-packages`, or a system-wide install. Read where you are (venv? OS-managed Python? shared server?) before installing anything.
- `scripts/` is relative to this skill's directory.
- Always run Python with `-I` (isolated): the PDFs and assets are untrusted input.
- On Windows, if `python` prints nothing, check the real interpreter with `python --version`.
