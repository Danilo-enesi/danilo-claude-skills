"""Check (and optionally install) the tools the pdf-design skills need.

Usage: python check_tools.py [--install]
--install never uses sudo/root or a global install: it installs into the active
virtualenv, else into the user site (pip --user). If the system Python is
externally managed (PEP 668) it stops and prints how to make a private venv.
Exit code 0 = everything required is available.
"""
import importlib, os, shutil, subprocess, sys, sysconfig

REQUIRED = {'pymupdf': 'pymupdf', 'PIL': 'pillow'}  # import name -> pip package
BROWSERS = [
    r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    r'C:\Program Files\Google\Chrome\Application\chrome.exe',
    r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge',
]
VENV = os.path.join(os.path.expanduser('~'), '.cache', 'pdf-design', 'venv')


def find_browser():
    for name in ('msedge', 'chrome', 'google-chrome', 'chromium', 'chromium-browser'):
        if shutil.which(name):
            return shutil.which(name)
    return next((p for p in BROWSERS if os.path.exists(p)), None)


def install_command(missing):
    """Least invasive pip command for this interpreter, or None if we must not touch it."""
    in_venv = sys.prefix != sys.base_prefix
    if in_venv:
        return [sys.executable, '-m', 'pip', 'install', *missing]
    if os.path.exists(os.path.join(sysconfig.get_path('stdlib'), 'EXTERNALLY-MANAGED')):
        return None  # PEP 668: the OS owns this Python
    return [sys.executable, '-m', 'pip', 'install', '--user', *missing]


def main():
    ok = sys.version_info >= (3, 9)
    print(f"python   {'OK' if ok else 'TOO OLD (need 3.9+)'}  {sys.version.split()[0]}  {sys.executable}")
    missing = []
    for mod, pkg in REQUIRED.items():
        try:
            importlib.import_module(mod)
            print(f'{pkg:8} OK')
        except ImportError:
            missing.append(pkg)
            print(f'{pkg:8} MISSING')
    if missing:
        cmd = install_command(missing)
        if cmd is None:
            print('this Python is managed by the OS: do not install into it. Use a private venv:')
            print(f'  {sys.executable} -m venv "{VENV}"')
            print(f'  then run the pdf-design scripts with the venv python')
        elif '--install' in sys.argv:
            subprocess.check_call(cmd)
            print('installed:', ' '.join(missing))
            missing = []
        else:
            print('install with:', ' '.join(f'"{c}"' if ' ' in c else c for c in cmd))
    b = find_browser()
    print(f"browser  {'OK ' + b if b else 'MISSING (needed only by html-visual-diff: install Edge or Chrome)'}")
    sys.exit(0 if ok and not missing else 1)


if __name__ == '__main__':
    main()
