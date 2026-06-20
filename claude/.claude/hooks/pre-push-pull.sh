#!/bin/bash
set -euo pipefail

# pulls latest changes (with rebase) before any git push
# supports git -C <dir> push as well
# skips force pushes (they are blocked by pre-bash-check.sh)
# on conflict: aborts the partial rebase and emits a block message

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" || echo "")

[ -z "$CMD" ] && exit 0

# only run for git push commands (push must be the subcommand, not a filename substring)
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b' || exit 0

# skip force pushes - they should be blocked by pre-bash-check.sh
echo "$CMD" | grep -qE '(--force|--force-with-lease|--force-if-includes)' && exit 0
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s-[a-zA-Z]*f[a-zA-Z]*\b' && exit 0
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s\+\S' && exit 0

# extract -C <dir> if present
DIR=$(echo "$CMD" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p')

if [ -n "$DIR" ]; then
  GIT_CMD=(git -C "$DIR")
else
  GIT_CMD=(git)
fi

# skip pull when the current branch has no upstream tracking
# (typical for a first-time push of a new branch)
BRANCH=$("${GIT_CMD[@]}" branch --show-current || echo "")
if [ -n "$BRANCH" ]; then
  REMOTE=$("${GIT_CMD[@]}" config --get "branch.${BRANCH}.remote" || true)
  if [ -z "$REMOTE" ]; then
    exit 0
  fi
fi

# attempt pull --rebase, capture combined output
if ! OUTPUT=$("${GIT_CMD[@]}" pull --rebase 2>&1); then
  # abort the partial rebase if one is in progress
  "${GIT_CMD[@]}" rebase --abort || true

  export OUTPUT
  python3 -c "
import json, os
reason = 'Pull --rebase before push failed. Rebase was aborted. Push blocked.\n\nGit output:\n' + os.environ.get('OUTPUT', '')
print(json.dumps({'decision': 'block', 'reason': reason}))
"
fi

exit 0
