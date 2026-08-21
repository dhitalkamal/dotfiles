#!/bin/bash
set -euo pipefail

# Stop hook: refuses to let a turn end if this session wrote several new
# source files on a feat/ branch without ever calling AskUserQuestion
# anywhere in the transcript - the mechanical version of the
# design/threat-modeling requirement that, until now, only lived in
# CLAUDE.md and SKILL.md text. Text competes for attention and auto
# mode's keep-going bias can win; this cannot be skipped the same way,
# because Claude Code itself won't let the turn end while this hook
# returns exit 2.
#
# this is a genuinely stronger mechanism than anything else built for
# this problem so far (CLAUDE.md trigger, SKILL.md AskUserQuestion
# requirement, --append-system-prompt-file) - all of those are text the
# model has to notice and choose to act on. this is code that mechanically
# inspects the transcript and refuses to proceed regardless of whether
# the model "noticed" anything.
#
# scope and safety valve, both deliberate:
# - only fires on a feat/ branch - fixes/chores never needed this stage
# - only fires once at least 3 distinct new source files were written -
#   a one or two file change doesn't warrant blocking the whole turn
# - gives up after 2 consecutive blocks in the same session, so a model
#   that doesn't respond correctly to the guidance can't be trapped in an
#   infinite loop - this mirrors auto mode's own classifier fallback
#   (gives up after repeated blocks rather than looping forever)

INPUT=$(cat)
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" || echo "")
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" || echo "")

[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0
[ -z "$SESSION_ID" ] && exit 0

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || echo "")
case "$BRANCH" in
	feat/*) ;;
	*) exit 0 ;;
esac

COUNTER_FILE="/tmp/.workflow-gate-count-${SESSION_ID}"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)

if [ "$COUNT" -ge 2 ]; then
	rm -f "$COUNTER_FILE"
	exit 0
fi

if grep -q '"name":"AskUserQuestion"' "$TRANSCRIPT" 2>/dev/null; then
	rm -f "$COUNTER_FILE"
	exit 0
fi

SOURCE_WRITES=$(grep -oE '"file_path":"[^"]*\.(swift|ts|tsx|js|jsx|py|go|rs|java|kt|rb)"' "$TRANSCRIPT" 2>/dev/null | sort -u | wc -l | tr -d ' ')

if [ "$SOURCE_WRITES" -ge 3 ]; then
	echo $((COUNT + 1)) > "$COUNTER_FILE"
	echo "this session wrote ${SOURCE_WRITES} distinct source files on branch '${BRANCH}' without ever calling AskUserQuestion for design or threat modeling. before ending this turn: actually ask a real, specific design/threat-modeling question via AskUserQuestion about this feature - not a note, not a task-list entry, an actual tool call. if this genuinely doesn't need one, say so explicitly and why, then you may stop." >&2
	exit 2
fi

rm -f "$COUNTER_FILE"
exit 0
