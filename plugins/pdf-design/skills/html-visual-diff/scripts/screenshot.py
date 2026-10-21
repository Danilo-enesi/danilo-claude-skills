"""Screenshot an HTML file or URL with headless Edge/Chrome (no Playwright, no new dependency).

Usage: python screenshot.py <file.html|url> <out.png> [--width 600] [--height 3000]
The browser window is --width wide; trailing empty space below the page is trimmed.
"""
import argparse, os, pathlib, subprocess, sys, tempfile
from PIL import Image, ImageChops

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[2] / 'pdf-design-tools' / 'scripts'))
from check_tools import find_browser  # noqa: E402  (shared browser lookup)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('out')
    ap.add_argument('--width', type=int, default=600)
    ap.add_argument('--height', type=int, default=3000)
    a = ap.parse_args()
    browser = find_browser()
    if not browser:
        sys.exit('no Edge/Chrome found: run pdf-design-tools')
    url = a.src if '://' in a.src else pathlib.Path(a.src).resolve().as_uri()
    with tempfile.TemporaryDirectory() as profile:  # throwaway profile: never touches the user's browser data
        subprocess.run([browser, '--headless=new', '--disable-gpu', '--hide-scrollbars', f'--user-data-dir={profile}',
                        f'--window-size={a.width},{a.height}', f'--screenshot={os.path.abspath(a.out)}', url],
                       capture_output=True, timeout=120)
    if not os.path.exists(a.out):
        sys.exit('screenshot failed')
    img = Image.open(a.out).convert('RGB')
    bg = Image.new('RGB', img.size, img.getpixel((img.width - 1, img.height - 1)))
    box = ImageChops.difference(img, bg).getbbox()
    if box:
        img = img.crop((0, 0, img.width, box[3]))
    img.save(a.out)
    print(f'{a.out}  {img.width}x{img.height}')


if __name__ == '__main__':
    main()
