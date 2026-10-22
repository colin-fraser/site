"""Screenshot pages of the locally built site in light and dark mode.

Usage: shoot.py OUT_PREFIX PATH [SCROLL_TO_SELECTOR] [NTH]
Run it through the `shoot` wrapper next to this file, which sets up Playwright.
Serves this checkout's _site/ on a local port and writes OUT_PREFIX-light.png
and OUT_PREFIX-dark.png. A bare OUT_PREFIX (no directory) goes in _shots/.
"""
import functools
import http.server
import sys
import threading
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "_site"

out, path = Path(sys.argv[1]), sys.argv[2]
selector = sys.argv[3] if len(sys.argv) > 3 else None
nth = int(sys.argv[4]) if len(sys.argv) > 4 else 0

if not (SITE / path).is_file():
    sys.exit(f"{SITE / path} not found; run `quarto render` first?")
if out.parent == Path("."):
    out = ROOT / "_shots" / out
out.parent.mkdir(parents=True, exist_ok=True)

class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


handler = functools.partial(Quiet, directory=SITE)
server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{server.server_port}/{path}"

with sync_playwright() as p:
    browser = p.chromium.launch()
    for scheme in ("light", "dark"):
        page = browser.new_page(
            viewport={"width": 1200, "height": 900}, color_scheme=scheme
        )
        page.goto(url, wait_until="networkidle")
        if selector:
            page.locator(selector).nth(nth).scroll_into_view_if_needed()
            page.evaluate("window.scrollBy(0, -150)")
        page.wait_for_timeout(300)
        page.screenshot(path=f"{out}-{scheme}.png")
        print(f"{out}-{scheme}.png")
        page.close()
    browser.close()
server.shutdown()
