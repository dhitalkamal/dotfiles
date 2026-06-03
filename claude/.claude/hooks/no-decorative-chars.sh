#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" || echo "")

[ -z "$FILE" ] && exit 0
[ ! -f "$FILE" ] && exit 0

python3 - "$FILE" <<'PY'
import sys

# explicit forbidden code points
forbidden = {
    # dashes and bars
    0x2010, 0x2011, 0x2012, 0x2013, 0x2014, 0x2015,
    # ellipsis and middle dot
    0x2026, 0x00B7, 0x2027,
    # bullets and stars
    0x2022, 0x2023, 0x2043, 0x204C, 0x204D,
    0x25E6, 0x25AA, 0x25AB, 0x25C6, 0x25C7,
    0x2605, 0x2606, 0x2727, 0x2729, 0x272A, 0x272B, 0x272D, 0x272F,
    # smart quotes
    0x2018, 0x2019, 0x201A, 0x201B,
    0x201C, 0x201D, 0x201E, 0x201F,
    0x00AB, 0x00BB,
    # multiplication sign
    0x00D7,
}

# unicode ranges (inclusive)
ranges = [
    (0x2190, 0x21FF),   # arrows
    (0x2500, 0x257F),   # box drawing
    (0x2580, 0x259F),   # block elements
    (0x25A0, 0x25FF),   # geometric shapes
    (0x2600, 0x26FF),   # misc symbols
    (0x2700, 0x27BF),   # dingbats
    (0x1F300, 0x1F9FF), # emoji and pictographs
    (0x1FA70, 0x1FAFF), # symbols and pictographs extended-a
]

def is_forbidden(c):
    cp = ord(c)
    if cp in forbidden:
        return True
    for lo, hi in ranges:
        if lo <= cp <= hi:
            return True
    return False

path = sys.argv[1]
try:
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
except (UnicodeDecodeError, OSError):
    sys.exit(0)

hits = []
for i, line in enumerate(lines, 1):
    bad = sorted({c for c in line if is_forbidden(c)})
    if bad:
        hits.append((i, line.rstrip('\n'), ''.join(bad)))

if hits:
    print(f"Decorative characters found in {path}:")
    for ln, text, chars in hits:
        print(f"  line {ln}  chars={chars!r}  {text}")
    print()
    print("ZERO decoration policy. Forbidden: em/en dashes, arrows,")
    print("bullets, box-drawing, smart quotes, ellipsis, emojis,")
    print("geometric shapes, dingbats. Use plain ASCII only.")
    sys.exit(2)
PY
