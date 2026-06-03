#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" || echo "")

[ -z "$FILE" ] && exit 0

# only .py files
[[ "$FILE" != *.py ]] && exit 0

# only files under apps/
[[ "$FILE" != */apps/* ]] && exit 0

# skip test and migration directories
[[ "$FILE" == */tests/* ]] && exit 0
[[ "$FILE" == */test/* ]] && exit 0
[[ "$FILE" == */migrations/* ]] && exit 0

# skip non-logic files
BASENAME=$(basename "$FILE")
case "$BASENAME" in
    __init__.py|apps.py|container.py|urls.py|wsgi.py|asgi.py|conftest.py|admin.py|settings.py) exit 0 ;;
esac

MODULE="${BASENAME%.py}"
SERVICE_ROOT=$(echo "$FILE" | sed 's|/apps/.*||')
[ -z "$SERVICE_ROOT" ] && SERVICE_ROOT="."

TEST_FOUND=$(find "$SERVICE_ROOT" \( -path "*/tests/*" -o -path "*/test/*" \) \
    \( -name "test_${MODULE}.py" -o -name "${MODULE}_test.py" \) 2>/dev/null | head -1 || true)

if [ -z "$TEST_FOUND" ]; then
    python3 -c "
import json
print(json.dumps({
    'decision': 'block',
    'reason': 'TDD violation: no test found for ${MODULE}.py. Write the test first, then the implementation.'
}))
"
fi

exit 0
