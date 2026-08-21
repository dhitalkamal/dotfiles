#!/bin/bash
# blocks writes to active tooling dirs.
# proposed hooks, skills, or agents must land in ~/.claude/pending/ instead.
# reads tool input from stdin as json.
#
# 2026-08-13: only enforced in headless/routine/ci. interactive sessions are
# already human-supervised turn by turn, so the gate no longer blocks those.
# same session/mode-detection idiom as log-headless-action.sh.

set -euo pipefail

session_id="${CLAUDE_SESSION_ID:-$$}"
env_file="${HOME}/.claude/session-env/${session_id}.env"

mode="interactive"
if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    . "$env_file"
    mode="${CLAUDE_EXEC_MODE:-interactive}"
fi

if [ "$mode" = "interactive" ]; then
    cat >/dev/null 2>&1 || true
    exit 0
fi

input=$(cat)

# extract file_path from Write or Edit tool input.
target=$(printf '%s' "$input" | /usr/bin/python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)
tool_input = data.get("tool_input") or {}
path = tool_input.get("file_path") or tool_input.get("path") or ""
print(path)
' 2>/dev/null || printf '')

if [ -z "$target" ]; then
    exit 0
fi

# normalize path.
case "$target" in
    /*) abs="$target" ;;
    *)  abs="$(pwd)/$target" ;;
esac

# resolve HOME expansion.
abs="${abs/#\~/$HOME}"

protected_prefixes=(
    "$HOME/dotfiles/claude/.claude/hooks/"
    "$HOME/dotfiles/claude/.claude/agents/"
    "$HOME/dotfiles/claude/.claude/settings.json"
    "$HOME/dotfiles/claude/.claude/CLAUDE.md"
    "$HOME/.claude/hooks/"
    "$HOME/.claude/settings.json"
    "$HOME/.claude/CLAUDE.md"
)

for prefix in "${protected_prefixes[@]}"; do
    case "$abs" in
        "$prefix"*|"$prefix")
            reason="write to active tooling path is gated outside interactive sessions. drop the draft in ~/.claude/pending/ (hooks|skills|agents subdir) and ask a human to promote it. blocked path: ${abs}"
            cat <<EOF2
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"${reason}"}}
EOF2
            exit 0
            ;;
    esac
done

exit 0
