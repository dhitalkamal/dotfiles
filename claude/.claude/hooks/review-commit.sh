#!/bin/bash
set -euo pipefail

# PostToolUse command hook, gated by if:"Bash(git commit *)" in settings.json,
# so it only runs after a git commit lands - not on every Bash call the way the
# old type:agent hook did. that hook spawned a sonnet agent on every command and
# self-aborted on non-commits, because `if` does not gate agent-type spawns, only
# command-type ones. this rewrite eliminates that waste while keeping the llm
# review and the security-advisor secret scan.
#
# a git commit cannot be blocked here - it already happened - so this is purely
# advisory. it shells out to a headless `claude -p` review (sonnet) that inspects
# the commit and runs the security-advisor scan_secrets mcp tool. output is teed
# to a timestamped log under ~/.claude/logs/commit-reviews/ and also printed, so
# findings are visible in the transcript and durably recorded.
#
# promotion (human review gate): move this to ~/.claude/hooks/review-commit.sh,
# chmod +x, then repoint the settings.json PostToolUse Bash hook from the current
# type:agent entry to:
#   { "type": "command", "if": "Bash(git commit *)",
#     "command": "~/.claude/hooks/review-commit.sh", "timeout": 120,
#     "statusMessage": "Reviewing the commit that just landed..." }

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
HOOK_CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || echo "")

# defensive: the settings.json `if` gate should already scope this to git commit,
# but re-check so a manual or mis-wired call cannot fire the review on anything else
echo "$CMD" | grep -qE '\bgit([[:space:]]+-C[[:space:]]+\S+)?[[:space:]]+commit\b' || exit 0

# resolve the repo dir: prefer an explicit git -C target on the command line, else
# the tool call's cwd. bail quietly if we cannot land inside a work tree.
REPO_DIR="$HOOK_CWD"
CDIR=$(echo "$CMD" | grep -oE '\bgit[[:space:]]+-C[[:space:]]+\S+' | head -1 | awk '{print $3}' || true)
[ -n "$CDIR" ] && REPO_DIR="$CDIR"
[ -z "$REPO_DIR" ] && exit 0
git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

ROOT=$(git -C "$REPO_DIR" rev-parse --show-toplevel 2>/dev/null || echo "$REPO_DIR")

LOG_DIR="$HOME/.claude/logs/commit-reviews"
mkdir -p "$LOG_DIR"
HASH=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)
STAMP=$(date +%Y%m%d-%H%M%S 2>/dev/null || echo run)
LOG="$LOG_DIR/${STAMP}-${HASH}.log"

PROMPT="A git commit just landed and cannot be blocked - it is already committed. Review it for high-confidence, serious problems only: correctness bugs that would break the build or runtime, security issues (committed secrets/keys, injection, broken auth), and obviously incomplete or debug code (leftover console.log/print debugging, large commented-out blocks). Inspect with 'git show HEAD --stat' and 'git diff HEAD~1 HEAD', and run the security-advisor scan_secrets tool against the repo root. Be fast and pragmatic. If you find a serious problem, flag it clearly in one or two concise lines and suggest a fix-up (amend if not yet pushed, otherwise a follow-up commit) - advisory only, you cannot undo the commit. Do NOT flag style, formatting, or subjective preferences. If you find nothing serious, reply exactly: commit review: clean."

# run the review from the repo root so git and the mcp servers resolve correctly.
# allowedTools is scoped to the read-only commands the review needs plus the secret
# scanner, so the headless run cannot write anything. tee to the log and to stdout.
cd "$ROOT"
claude -p "$PROMPT" \
	--model claude-sonnet-5 \
	--add-dir "$ROOT" \
	--allowedTools "Bash(git show:*)" "Bash(git diff:*)" "Bash(git log:*)" "Bash(git rev-parse:*)" "mcp__security-advisor__scan_secrets" "Read" \
	2>&1 | tee "$LOG" || true

echo "commit review saved -> $LOG" >&2
exit 0
