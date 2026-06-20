#!/bin/bash
set -euo pipefail

# consolidated pre-bash hook: package manager, co-authored-by, branch, danger guard
# runs all checks in a single process instead of 4 separate ones

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" || echo "")

[ -z "$CMD" ] && exit 0

block() {
  python3 -c "import json; print(json.dumps({'decision': 'block', 'reason': '''$1'''}))"
  exit 0
}

# --- package manager checks ---

if echo "$CMD" | grep -qE '(^|[;|&])\s*pip3?\b' && ! echo "$CMD" | grep -qE '(^|[;|&])\s*uv\s+pip\b'; then
  block "Use uv instead of pip/pip3. Example: uv add <package> or uv run pip install <package>"
fi

if echo "$CMD" | grep -qE '(^|[;|&])\s*python3?\b' && ! echo "$CMD" | grep -qE '(^|[;|&])\s*python3?\s+manage\.py\b'; then
  block "Use uv run instead of python/python3 directly. Example: uv run python <script> or uv run pytest"
fi

if echo "$CMD" | grep -qE '(^|[;|&])\s*npm\b'; then
  block "Use yarn instead of npm. Example: yarn add <package> or yarn dev"
fi

if echo "$CMD" | grep -qE '(^|[;|&])\s*npx\b'; then
  block "Use yarn instead of npx. Example: yarn dlx <package> or yarn <script>"
fi

# --- git commit checks (co-authored-by + branch) ---

if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+commit\b'; then
  if echo "$CMD" | grep -qi "co-authored-by"; then
    block "Remove Co-Authored-By from the commit message. Rewrite the commit without it."
  fi

  BRANCH=$(git branch --show-current || echo "")
  if [ -n "$BRANCH" ]; then
    case "$BRANCH" in
      feat/*|fix/*|chore/*)
        # allowed prefixes
        ;;
      *)
        block "Commits allowed only on feat/<slug>, fix/<slug>, or chore/<slug>. Current branch: ${BRANCH}. Create one: git checkout develop && git checkout -b feat/<slug>"
        ;;
    esac
  fi
fi

# --- git push force checks ---

if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b'; then
  if echo "$CMD" | grep -qE '(--force|--force-with-lease|--force-if-includes)'; then
    block "Force push is not allowed. Never. Push without --force."
  fi
  if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s-[a-zA-Z]*f[a-zA-Z]*\b'; then
    block "Force push is not allowed (short -f flag detected). Never."
  fi
  if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s\+\S'; then
    block "Force push via +refspec is not allowed. Never."
  fi
fi

# --- danger guard: destructive sql + filesystem ---

UPPER_CMD=$(echo "$CMD" | tr '[:lower:]' '[:upper:]')

if echo "$UPPER_CMD" | grep -qE '\bDROP\s+(TABLE|DATABASE|SCHEMA)\b'; then
  block "Blocked: DROP TABLE/DATABASE/SCHEMA detected. Confirm this is intentional before running manually."
fi

if echo "$UPPER_CMD" | grep -qE '\bTRUNCATE\s+TABLE\b'; then
  block "Blocked: TRUNCATE TABLE detected. This permanently deletes all rows."
fi

if echo "$UPPER_CMD" | grep -qE '\bDELETE\s+FROM\b' && ! echo "$UPPER_CMD" | grep -qE '\bWHERE\b'; then
  block "Blocked: DELETE FROM without WHERE clause - this deletes all rows. Add a WHERE clause or run manually if intentional."
fi

if echo "$CMD" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r'; then
  if echo "$CMD" | grep -qE '(rm\s+.*(/\s*$|~\s*$|\$HOME))|(rm\s+.*-rf\s+(/|\.{1,2}(\s|$)|\*))'; then
    block "Blocked: rm -rf on dangerous target (root, home, current/parent dir, or wildcard) detected."
  fi
fi

if echo "$CMD" | grep -qE '\bdropdb\b'; then
  block "Blocked: dropdb detected. Run manually if intentional."
fi

exit 0
