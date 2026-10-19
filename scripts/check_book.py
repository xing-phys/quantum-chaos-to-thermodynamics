#!/usr/bin/env python3
"""Check source labels/citations and every rendered local HTML link/fragment.

Standard library only; run after `quarto render`. External links are not crawled.
"""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
from collections import Counter
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / '_site'
errors = []

class Page(HTMLParser):
    def __init__(self, path):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.links = []
        self.text = []
        self.feed(path.read_text())
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if key in attrs:
                self.links.append(attrs[key])
        if 'quarto-unresolved-ref' in attrs.get('class', ''):
            errors.append('Unresolved reference in rendered HTML')
    def handle_data(self, data):
        self.text.append(data)

sources = list(ROOT.glob('*.qmd'))
bibs = list((ROOT/'assets').glob('*.bib'))
keys = re.findall(r'@\w+\s*\{\s*([^,\s]+)', '\n'.join(p.read_text() for p in bibs))
for key, count in Counter(keys).items():
    if count > 1:
        errors.append(f'Duplicate bibliography key: {key}')
labels = []
citations = set()
for source in sources:
    text = source.read_text()
    labels += re.findall(r'\{#([\w-]+)', text)
    citations |= set(re.findall(r'(?<![\w/])@([\w][\w:.-]*)', text))
for label, count in Counter(labels).items():
    if count > 1:
        errors.append(f'Duplicate source label: {label}')
for key in citations:
    if key not in keys and key not in labels:
        errors.append(f'Unresolved source citation or cross-reference: {key}')

pages = {p.resolve(): Page(p) for p in SITE.rglob('*.html')}
if not pages:
    errors.append('No rendered HTML pages found')
for path, page in pages.items():
    for link in page.links:
        url = urlsplit(link)
        if url.scheme or url.netloc or link.startswith('//'):
            continue
        relative = unquote(url.path)
        if relative.startswith('/quantum-chaos-to-thermodynamics/'):
            target = SITE / relative.removeprefix('/quantum-chaos-to-thermodynamics/')
        elif relative.startswith('/'):
            target = SITE / relative.lstrip('/')
        else:
            target = path.parent / relative if relative else path
        if target.is_dir():
            target /= 'index.html'
        target = target.resolve()
        if not target.exists():
            errors.append(f'{path.name}: missing {link}')
        elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
            errors.append(f'{path.name}: missing anchor {link}')
    rendered = ''.join(page.text)
    if re.search(r'\[\?\??\]|\?\?\s*\(', rendered):
        errors.append(f'{path.name}: possible unresolved rendered reference')

pdf = SITE / 'quantum-chaos-to-thermodynamics.pdf'
if not pdf.is_file() or not pdf.read_bytes().startswith(b'%PDF-'):
    errors.append('Combined PDF is missing or invalid')

if errors:
    print('\n'.join(dict.fromkeys(errors)), file=sys.stderr)
    sys.exit(1)
print(f'PASS: {len(sources)} sources; {len(keys)} bibliography entries; '
      f'{len(labels)} labels; {len(pages)} HTML pages; local links and PDF.')
