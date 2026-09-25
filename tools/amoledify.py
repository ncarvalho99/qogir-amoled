#!/usr/bin/env python3
"""Recolor Qogir dark files to the AMOLED palette in tools/palette.tsv.

Handles hex colors (#rrggbb, any case) in any text file and R,G,B triplets in
KDE color scheme / Aurorae rc files. Compressed .svgz files are rewritten in place.

Usage: amoledify.py FILE_OR_DIR...
"""
import gzip
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEXT_EXTS = ('.svg', '.svgz', '.scss', '.css', '.colors', '.kvconfig', 'rc', '.qml', '.desktop', '.json')


def load_palette():
    mapping = {}
    with open(os.path.join(HERE, 'palette.tsv')) as f:
        for line in f:
            line = line.split('#', 1)[0].strip()
            if line:
                old, new = line.split()
                mapping[old.lower()] = new.lower()
    return mapping


PALETTE = load_palette()
HEX_RE = re.compile(r'#([0-9a-fA-F]{6})\b')
TRIPLET_RE = re.compile(r'(?<=[=,\s])(\d{1,3}),(\d{1,3}),(\d{1,3})\b')
TRIPLETS = {
    tuple(int(old[i:i + 2], 16) for i in (0, 2, 4)): tuple(int(new[i:i + 2], 16) for i in (0, 2, 4))
    for old, new in PALETTE.items()
}


def recolor_hex(match):
    new = PALETTE.get(match.group(1).lower())
    return '#' + new if new else match.group(0)


def recolor_triplet(match):
    new = TRIPLETS.get(tuple(int(g) for g in match.groups()))
    return ','.join(map(str, new)) if new else match.group(0)


def recolor(text, triplets):
    text = HEX_RE.sub(recolor_hex, text)
    if triplets:
        text = TRIPLET_RE.sub(recolor_triplet, text)
    return text


def process(path):
    triplets = path.endswith(('.colors', 'rc', 'colors'))
    if path.endswith('.svgz'):
        with gzip.open(path, 'rt', encoding='utf-8') as f:
            old = f.read()
        new = recolor(old, triplets)
        if new != old:
            with gzip.open(path, 'wt', encoding='utf-8') as f:
                f.write(new)
            return True
        return False
    with open(path, encoding='utf-8') as f:
        old = f.read()
    new = recolor(old, triplets)
    if new != old:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new)
        return True
    return False


def walk(target):
    if os.path.isfile(target):
        yield target
        return
    for root, _, files in os.walk(target):
        for name in files:
            if name.endswith(TEXT_EXTS) or name == 'colors':
                yield os.path.join(root, name)


if __name__ == '__main__':
    changed = 0
    for target in sys.argv[1:]:
        for path in walk(target):
            changed += process(path)
    print(f'amoledify: {changed} file(s) recolored')
