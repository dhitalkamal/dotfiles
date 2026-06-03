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

# em dash U+2014, en dash U+2013, box-drawing chars
MATCHES=$(grep -nE '[—–─│┌┐└┘├┤┬┴┼]' "$FILE" || true)

if [ -n "$MATCHES" ]; then
  echo "Decorative characters found in $FILE:"
  echo "$MATCHES"
  echo ""
  echo "Remove all em dashes, en dashes, and box-drawing characters from these lines."
  exit 2
fi

exit 0
