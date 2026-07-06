#!/bin/bash
# appends non-interactive tool calls to a per-session log file.
# no-op in interactive mode.

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
    # discard stdin to be well-behaved and exit.
    cat >/dev/null 2>&1 || true
    exit 0
fi

log_dir="${CLAUDE_HEADLESS_LOG_DIR:-$HOME/.claude/logs/headless}"
mkdir -p "$log_dir"

log_file="${log_dir}/${session_id}.jsonl"
ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

payload=$(cat)
printf '{"ts":"%s","mode":"%s","event":%s}\n' \
    "$ts" "$mode" "$payload" >> "$log_file" 2>/dev/null || true

exit 0
