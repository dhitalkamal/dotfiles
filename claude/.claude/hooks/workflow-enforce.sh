#!/bin/bash
set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('prompt', ''))
" || echo "")

# PROCEED means the user has approved - stay silent and allow execution
if echo "$prompt" | grep -qw "PROCEED"; then
  exit 0
fi

python3 -c "
import json
msg = (
    'WORKFLOW - follow this for every prompt without exception:\n\n'
    '1. ANALYZE (silently): read relevant files, understand scope and context first.\n'
    '2. RESPOND IN ONE MESSAGE with all three:\n'
    '   a. Findings: what you discovered about the codebase/context\n'
    '   b. Questions: every clarifying question - mark unknowns in the plan as [UNKNOWN]\n'
    '   c. Draft plan: the complete proposed flow with [UNKNOWN] where answers affect decisions\n'
    '3. GATE: do not write code, run commands, or modify any files until the user replies\n'
    '   with the exact word PROCEED.\n'
    '   \"yes\", \"ok\", \"sure\", \"go ahead\", \"looks good\" are NOT approval.\n'
    '   If the user answers questions but does not say PROCEED, revise the plan and wait again.'
)
print(json.dumps({'additionalContext': msg}))
"
