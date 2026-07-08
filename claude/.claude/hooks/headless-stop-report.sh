#!/bin/bash
# writes a completion marker when a headless, routine, or ci session ends.
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

# consume stdin regardless.
cat >/dev/null 2>&1 || true

if [ "$mode" = "interactive" ]; then
    exit 0
fi

log_dir="${CLAUDE_HEADLESS_LOG_DIR:-$HOME/.claude/logs/headless}"
mkdir -p "$log_dir"

marker="${log_dir}/${session_id}.stop"
{
    echo "session_id=${session_id}"
    echo "mode=${mode}"
    echo "stopped_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "routine=${CLAUDE_ROUTINE_NAME:-}"
} > "$marker"

exit 0
