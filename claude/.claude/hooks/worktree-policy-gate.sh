#!/bin/bash
set -euo pipefail

# PreToolUse gate on Write|Edit: mechanically enforces "before making any
# filesystem change inside a git repo, ask worktree-or-direct-checkout,
# every time" from CLAUDE.md's Worktree policy section, which until now
# only lived in prose. Same rationale as feature-workflow-gate.sh: auto
# mode's keep-going bias can make a text-only instruction lose out to
# forward momentum, so this makes the first write in a git repo a hard
# stop until the question has actually been asked in this session.
#
# resolved automatically, no ask needed, if the target directory is
# already inside a worktree checkout (not the main checkout) - a worktree
# has a .git FILE pointing at .git/worktrees/<name> in the main repo, so
# git-common-dir and git-dir diverge there. reaching a worktree at all
# means the choice was already made when it was created.
#
# safety valve: gives up after 2 blocks in the same session, mirroring
# feature-workflow-gate.sh and auto mode's own classifier fallback, so a
# model that doesn't respond correctly can't be trapped in an infinite loop.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")
HOOK_CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0

TARGET_DIR="$HOOK_CWD"
if [ -n "$FILE_PATH" ]; then
	case "$FILE_PATH" in
		/*) TARGET_DIR=$(dirname "$FILE_PATH") ;;
		*) TARGET_DIR="$HOOK_CWD/$(dirname "$FILE_PATH")" ;;
	esac
fi
[ -z "$TARGET_DIR" ] && exit 0

# not a git repo at all - policy doesn't apply
git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

COMMON_DIR=$(git -C "$TARGET_DIR" rev-parse --git-common-dir 2>/dev/null || echo "")
GIT_DIR=$(git -C "$TARGET_DIR" rev-parse --git-dir 2>/dev/null || echo "")

# already inside a worktree checkout (not the main one) - the choice was
# already made when the worktree was created, nothing to ask here
if [ -n "$COMMON_DIR" ] && [ -n "$GIT_DIR" ] && [ "$COMMON_DIR" != "$GIT_DIR" ]; then
	exit 0
fi

COUNTER_FILE="/tmp/.worktree-gate-count-${SESSION_ID}"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)

if [ "$COUNT" -ge 2 ]; then
	exit 0
fi

[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

ASKED=$(TRANSCRIPT_PATH="$TRANSCRIPT" python3 -c "
import json, os

found = False
path = os.environ['TRANSCRIPT_PATH']
try:
	with open(path) as f:
		for line in f:
			line = line.strip()
			if not line:
				continue
			try:
				entry = json.loads(line)
			except json.JSONDecodeError:
				continue
			content = entry.get('message', {}).get('content', [])
			if not isinstance(content, list):
				continue
			for block in content:
				if not isinstance(block, dict) or block.get('type') != 'tool_use':
					continue
				name = block.get('name')
				if name == 'EnterWorktree':
					found = True
				elif name == 'AskUserQuestion' and 'worktree' in json.dumps(block.get('input', {})).lower():
					found = True
	print('yes' if found else 'no')
except Exception:
	print('no')
")

if [ "$ASKED" = "no" ]; then
	echo $((COUNT + 1)) > "$COUNTER_FILE"
	REASON="worktree policy: this is the first filesystem change in this git repo this session, and no AskUserQuestion mentioning worktree (or EnterWorktree call) is in the transcript yet. per CLAUDE.md Worktree policy, ask whether to work in an isolated worktree or directly in the current checkout before writing - every time, regardless of change size." \
	python3 -c "
import json, os
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'ask', 'permissionDecisionReason': os.environ['REASON']}}))
"
	exit 0
fi

rm -f "$COUNTER_FILE"
exit 0
