#!/usr/bin/env python3
"""Drop stray <style> blocks that redefine ColorScheme-* classes.

Some upstream Qogir Plasma SVGs carry a second stylesheet after the
"current-color-scheme" one. Plasma only rewrites the first, so the second
(with hard-coded Breeze light colors) wins and popups render light grey.

Usage: fix-svg-styles.py DIR
"""
import gzip
import os
import re
import sys

STYLE_RE = re.compile(r'<style\b[^>]*>.*?</style>', re.S)


def fix(text):
    def drop(match):
        block = match.group(0)
        if 'current-color-scheme' in block.split('>', 1)[0]:
            return block
        return '' if 'ColorScheme-' in block else block
    return STYLE_RE.sub(drop, text)


changed = 0
for root, _, files in os.walk(sys.argv[1]):
    for name in files:
        path = os.path.join(root, name)
        if name.endswith('.svgz'):
            opener = gzip.open
        elif name.endswith('.svg'):
            opener = open
        else:
            continue
        with opener(path, 'rt', encoding='utf-8') as f:
            old = f.read()
        new = fix(old)
        if new != old:
            with opener(path, 'wt', encoding='utf-8') as f:
                f.write(new)
            changed += 1
print(f'fix-svg-styles: {changed} file(s) fixed')
