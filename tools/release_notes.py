"""Prints the newest WHAT'S NEW entry from scripts/changelog.gd as Markdown.
Used by .github/workflows/release.yml for the GitHub Release notes."""
import re, sys
src = open(sys.argv[1] if len(sys.argv) > 1 else "scripts/changelog.gd", encoding="utf-8").read()
body = src[src.index("const ENTRIES"):]
m = re.search(r'\[\s*"([^"]+)",\s*"((?:[^"\\]|\\.)*)",\s*\[(.*?)\]\s*\]', body, re.S)
ver, title, items = m.group(1), m.group(2), m.group(3)
print(f"**Rewind Life Demo {ver}: {title}**\n")
for it in re.findall(r'"((?:[^"\\]|\\.)*)"', items):
    print("- " + it.replace('\\"', '"'))
print("\nThis is a demo of Rewind Life, an early playable slice of the game.")
