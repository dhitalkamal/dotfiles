#!/bin/bash
# blocks writes to active tooling dirs.
# proposed hooks, skills, or agents must land in ~/.claude/pending/ instead.
# reads tool input from stdin as json.

set -euo pipefail

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
            reason="write to active tooling path is gated. drop the draft in ~/.claude/pending/ (hooks|skills|agents subdir) and ask a human to promote it. blocked path: ${abs}"
            cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"${reason}"}}
EOF
            exit 0
            ;;
    esac
done

exit 0
