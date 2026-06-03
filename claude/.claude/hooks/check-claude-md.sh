#!/bin/bash
set -euo pipefail

# skip when started from home directory, not a project
if [ "$PWD" = "$HOME" ] || [ "$PWD" = "/" ]; then
  exit 0
fi

# walk up from PWD to find a CLAUDE.md (stops at home dir)
DIR="$PWD"
HOME_DIR="$HOME"

while [ "$DIR" != "/" ] && [ "$DIR" != "$HOME_DIR" ]; do
  if [ -f "$DIR/CLAUDE.md" ]; then
    exit 0
  fi
  DIR=$(dirname "$DIR")
done

python3 -c "
import json
msg = (
  'No CLAUDE.md found in this project. '
  'IMPORTANT: Before responding to the user request, do the following:\n'
  '1. Ask the user: \"This project has no CLAUDE.md. Would you like me to create one?\"\n'
  '2. If yes, ask these questions ONE AT A TIME, waiting for each answer before asking the next:\n'
  '   - What is the project or service name?\n'
  '   - What tech stack does it use? (e.g. Python/Django, Node/TypeScript)\n'
  '   - What database does it use and what is the schema name? (e.g. postgres -> myapp)\n'
  '   - Does it use a task queue? (celery / bullmq / none)\n'
  '   - What command runs the tests?\n'
  '   - What command runs the linter?\n'
  '   - Briefly describe the main domain areas or modules.\n'
  '3. Once all answers are collected, create CLAUDE.md in the project root using that info.\n'
  '4. Then proceed with the user original request.\n'
  'If they say no, proceed directly with their request.'
)
print(json.dumps({'additionalContext': msg}))
"
