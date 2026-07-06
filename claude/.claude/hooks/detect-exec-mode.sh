#!/bin/bash
# sets CLAUDE_EXEC_MODE based on how the session was launched.
# writes the mode to a session env file that later hooks source.
# does not block any tool; purely informational.

set -euo pipefail

mode="interactive"

# claude -p sets these hints. treat any of them as headless.
if [ -n "${CLAUDE_CODE_PRINT_MODE:-}" ] \
    || [ -n "${CLAUDE_HEADLESS:-}" ] \
    || [ -n "${ANTHROPIC_HEADLESS:-}" ]; then
    mode="headless"
fi

# cron and ScheduleWakeup runners set CLAUDE_ROUTINE_NAME.
if [ -n "${CLAUDE_ROUTINE_NAME:-}" ]; then
    mode="routine"
fi

# GitHub Actions and most CI systems set CI=true.
if [ "${CI:-}" = "true" ] || [ -n "${GITHUB_ACTIONS:-}" ]; then
    mode="ci"
fi

# stdin not a tty is a strong signal for non-interactive when no other hint.
if [ "$mode" = "interactive" ] && [ ! -t 0 ]; then
    # do not flip to headless purely on tty; ide sessions can lack tty.
    # only note it in the env file so downstream can decide.
    tty_missing=1
else
    tty_missing=0
fi

env_dir="${HOME}/.claude/session-env"
mkdir -p "$env_dir"

session_id="${CLAUDE_SESSION_ID:-$$}"
env_file="${env_dir}/${session_id}.env"

{
    echo "CLAUDE_EXEC_MODE=${mode}"
    echo "CLAUDE_SESSION_TTY_MISSING=${tty_missing}"
    echo "CLAUDE_SESSION_STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$env_file"

# emit as additional context via stdout so it lands in the session.
cat <<EOF
{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"exec_mode=${mode} tty_missing=${tty_missing} session_env=${env_file}"}}
EOF

exit 0
