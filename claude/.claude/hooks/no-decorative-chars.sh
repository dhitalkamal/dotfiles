#!/bin/bash
set -euo pipefail

# pre-tool-use hook. scans the content proposed by Write or new_string from Edit.
# blocks the operation if decorative or invisible characters are detected.

python3 -c "
import sys, json

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool = data.get('tool_name', '')
ti = data.get('tool_input', {})

if tool == 'Write':
    content = ti.get('content', '')
elif tool == 'Edit':
    content = ti.get('new_string', '')
else:
    sys.exit(0)

if not content:
    sys.exit(0)

forbidden = {
    0x2010, 0x2011, 0x2012, 0x2013, 0x2014, 0x2015,
    0x2026, 0x00B7, 0x2027,
    0x2022, 0x2023, 0x2043, 0x204C, 0x204D,
    0x25E6, 0x25AA, 0x25AB, 0x25C6, 0x25C7,
    0x2605, 0x2606, 0x2727, 0x2729, 0x272A, 0x272B, 0x272D, 0x272F,
    0x2018, 0x2019, 0x201A, 0x201B,
    0x201C, 0x201D, 0x201E, 0x201F,
    0x00AB, 0x00BB,
    0x00D7,
    0x00A0, 0x200B, 0xFEFF, 0x2028, 0x2029, 0x2009,
}

ranges = [
    (0x2190, 0x21FF),
    (0x2500, 0x257F),
    (0x2580, 0x259F),
    (0x25A0, 0x25FF),
    (0x2600, 0x26FF),
    (0x2700, 0x27BF),
    (0x1F300, 0x1F9FF),
    (0x1FA70, 0x1FAFF),
]

def is_forbidden(c):
    cp = ord(c)
    if cp in forbidden:
        return True
    for lo, hi in ranges:
        if lo <= cp <= hi:
            return True
    return False

hits = []
for i, line in enumerate(content.splitlines(), 1):
    bad = sorted({c for c in line if is_forbidden(c)})
    if bad:
        chars_repr = ' '.join(f'U+{ord(c):04X}' for c in bad)
        hits.append((i, line, chars_repr))

if hits:
    lines_out = ['Decorative or invisible characters in proposed content:']
    for ln, text, chars in hits:
        lines_out.append(f'  line {ln}  chars=[{chars}]  {text}')
    lines_out.append('')
    lines_out.append('ZERO decoration policy. Forbidden: em/en dashes, arrows,')
    lines_out.append('bullets, box-drawing, smart quotes, ellipsis, emojis,')
    lines_out.append('geometric shapes, dingbats, invisible spaces. ASCII only.')
    msg = '\n'.join(lines_out)
    print(json.dumps({'decision': 'block', 'reason': msg}))
"
