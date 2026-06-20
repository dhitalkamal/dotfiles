#!/bin/bash
set -euo pipefail

# UserPromptSubmit hook.
# Nudges the assistant to offer creating a CLAUDE.md when none exists in the project.
# Skips when:
# - PWD is $HOME or /
# - a CLAUDE.md exists in any ancestor up to $HOME
# - a .claude/.md-skip marker exists in any ancestor up to $HOME

if [ "$PWD" = "$HOME" ] || [ "$PWD" = "/" ]; then
  exit 0
fi

DIR="$PWD"
HOME_DIR="$HOME"

while [ "$DIR" != "/" ] && [ "$DIR" != "$HOME_DIR" ]; do
  if [ -f "$DIR/CLAUDE.md" ]; then
    exit 0
  fi
  if [ -f "$DIR/.claude/.md-skip" ]; then
    exit 0
  fi
  DIR=$(dirname "$DIR")
done

python3 -c "
import json
msg = (
  'No CLAUDE.md found in this project. Following the workflow rule, '
  'offer to create one if relevant and ask the user for the project '
  'context needed (name, stack, db, tests, lint, domain areas, etc). '
  'If the user declines or says skip, create an empty marker at '
  '.claude/.md-skip in the project root to silence future nudges.'
)
print(json.dumps({'additionalContext': msg}))
"
