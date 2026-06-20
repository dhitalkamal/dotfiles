#!/bin/bash
set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(data.get('prompt', ''))
" || echo "")

# PROCEED counts as approval only when it is the final word of the prompt
# (after trailing punctuation). Mentions of PROCEED mid-sentence do not count.
LAST_WORD=$(echo "$prompt" | awk 'NF{last=$NF} END{print last}' | sed -E 's/[.,:;!]+$//')
if [ "$LAST_WORD" = "PROCEED" ]; then
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
    '   with PROCEED as the final word of their message.\n'
    '   \"yes\", \"ok\", \"sure\", \"go ahead\", \"looks good\" are NOT approval.\n'
    '   PROCEED mid-sentence is not approval either - it must be the final word.\n'
    '   If the user answers questions but does not end with PROCEED, revise the plan and wait again.'
)
print(json.dumps({'additionalContext': msg}))
"
