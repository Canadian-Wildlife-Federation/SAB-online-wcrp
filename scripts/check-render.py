"""Check the generated book for missing local pages, assets, and HTML anchors."""

from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.targets = []
        self.ids = set()

    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if attrs.get("id"):
            self.ids.add(attrs["id"])
        if tag == "a" and attrs.get("name"):
            self.ids.add(attrs["name"])
        key = "href" if tag in {"a", "link"} else "src"
        if tag in {"a", "link", "img", "script", "iframe", "source"} and attrs.get(key):
            self.targets.append(attrs[key])


root = Path(__file__).resolve().parents[1]
config = yaml.safe_load((root / "_quarto.yml").read_text(encoding="utf-8"))
output = root / config["project"]["output-dir"]
errors = set()
pages = {}
for source in config["book"]["chapters"] + config["book"].get("appendices", []):
    expected = output / Path(source).with_suffix(".html")
    if not expected.is_file():
        errors.add(f"Missing rendered chapter: {expected.relative_to(root)}")

for page in output.rglob("*.html"):
    parser = Links()
    parser.feed(page.read_text(encoding="utf-8"))
    pages[page.resolve()] = parser

for page, parser in pages.items():
    for link in parser.targets:
        url = urlsplit(link)
        if url.scheme or url.netloc:
            continue
        path = unquote(url.path)
        if not path:
            target = page
        elif path.startswith("/"):
            target = (output / path.lstrip("/")).resolve()
        else:
            target = (page.parent / path).resolve()
        if target.is_dir():
            target /= "index.html"
        if not target.is_relative_to(output.resolve()):
            errors.add(f"{page.relative_to(root)}: link escapes published site: {link}")
        elif not target.exists():
            errors.add(f"{page.relative_to(root)}: missing {link}")
        elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
            errors.add(f"{page.relative_to(root)}: missing anchor {link}")

if errors:
    print("\n".join(sorted(errors)))
    raise SystemExit(1)
print(f"Checked {len(pages)} HTML pages: all configured chapters and local links/assets/anchors exist.")
