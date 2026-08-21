#!/bin/bash
set -euo pipefail

# fast-forwards local to remote before any git push (no rebase, no merge)
# supports git -C <dir> push as well
# skips force pushes (they are blocked by pre-bash-check.sh)
# on non-ff: emits a block message and lets the human decide how to integrate
#
# 2026-08-12 fix: a bare `git push` (no -C, no leading `cd`) previously fell back
# to the hook process's own cwd, which is the project root and often not a git
# repo itself ("fatal: not a git repository"), blocking every such push. Now
# falls back to the tool call's actual cwd (from the hook JSON payload) before
# giving up, since that's normally the real repo directory.
#
# 2026-08-12 fix 2: the `cd <dir> &&` detection used `\s` in sed -E, which BSD/macOS
# sed does not treat as whitespace, so it silently failed to match and fell through
# to HOOK_CWD (wrong repo). Switched to [[:space:]] to match the -C extraction above.
# Also pipe through `head -1`: if a single tool call bundles more than one
# `git push` command, sed's `p` prints one captured path per matching line, and
# command substitution joins them with a newline into one broken multi-line DIR.
#
# 2026-08-16 fix 3: two more resolution failures found live, same root cause as
# git-branch-guard.sh's fix - text-pattern matching on the raw command string
# cannot know what a `cd` on an earlier line, a `cd "$VAR"`, or a leading `~`
# actually resolve to. `~/path` was being passed to `git -C` literally
# (no shell ever expanded it, since the hook reads the raw command string, not
# a post-expansion argv), so `git -C '~/path'` failed with "cannot change to"
# and got reported as a pull/rebase failure, which was misleading - the
# directory was never real to begin with. Now: `~` is expanded explicitly
# where it appears as a leading path segment, and anything else this script
# cannot confidently resolve (multi-line cd, a `$VAR` target) blocks with a
# clear reason instead of silently resolving to the wrong directory and
# reporting a confusing git error as if it were a real divergence.
#
# 2026-08-17 fix 4: DIR resolution grabbed the first -C anywhere in the
# (possibly multi-line, multi-command) $CMD string via head -1, regardless of
# which line actually contained the push. found live: a batched setup script
# with an unrelated `git -C <other-repo> init --bare` line before the real
# push line resolved DIR to that unrelated, sometimes-not-yet-existing
# directory, and reported "pull failed" when the real problem was resolving
# to the wrong repo entirely. now resolution is restricted to the line(s)
# that actually contain the push, and if those lines disagree on more than
# one distinct -C value, that blocks as ambiguous too.

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" || echo "")
HOOK_CWD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" || echo "")

[ -z "$CMD" ] && exit 0

# only run for git push commands (push must be the subcommand, not a filename substring)
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b' || exit 0

# skip force pushes - they should be blocked by pre-bash-check.sh
echo "$CMD" | grep -qE '(--force|--force-with-lease|--force-if-includes)' && exit 0
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s-[a-zA-Z]*f[a-zA-Z]*\b' && exit 0
echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b.*\s\+\S' && exit 0

block_ambiguous() {
	python3 -c "
import json, sys
reason = 'Could not safely determine the target repo directory for this push (it changes directory via a shell variable, a separate line, another form this guard cannot resolve as plain text, or multiple conflicting -C targets in the same batched command). Push blocked rather than risk skipping the pre-push pull check. Retry as a single line with a literal absolute path, e.g. cd /abs/path && git push ..., or git -C /abs/path push ...'
print(json.dumps({'decision': 'block', 'reason': reason}))
"
	exit 0
}

# expand a leading ~ the way a shell would, since the hook sees the raw
# command string, not a post-expansion argv - git -C never expands it itself.
expand_tilde() {
	case "$1" in
		"~") echo "$HOME" ;;
		"~/"*) echo "$HOME/${1#\~/}" ;;
		*) echo "$1" ;;
	esac
}

# scope resolution to the line(s) that actually contain the push, so an
# unrelated -C on an earlier line in a batched multi-command string cannot
# be mistaken for this push's target directory (see fix 4 above).
PUSH_LINES=$(echo "$CMD" | grep -E '\bgit(\s+-C\s+\S+)?\s+push\b' || true)
[ -z "$PUSH_LINES" ] && PUSH_LINES="$CMD"

DISTINCT_C=$(echo "$PUSH_LINES" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | sort -u | wc -l | tr -d ' ')
if [ "$DISTINCT_C" -gt 1 ]; then
	block_ambiguous
fi

# resolve the repo directory: explicit `-C <dir>` wins, then a leading `cd <dir> &&`,
# then the tool call's actual cwd (the hook process's own cwd is the project root,
# which is often not a git repo itself, so it's not a usable fallback). anything
# this cannot resolve with confidence blocks instead of guessing - see fix 3/4 above.
DIR=$(echo "$PUSH_LINES" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
if [ -n "$DIR" ]; then
	case "$DIR" in
		*'$'*) block_ambiguous ;;
		*) DIR=$(expand_tilde "$DIR") ;;
	esac
else
	DIR=$(echo "$PUSH_LINES" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*&&.*/\1/p' | head -1)
	if [ -n "$DIR" ]; then
		case "$DIR" in
			*'$'*) block_ambiguous ;;
			*) DIR=$(expand_tilde "$DIR") ;;
		esac
	elif echo "$CMD" | grep -qE '(^|[;&|])[[:space:]]*cd[[:space:]]'; then
		block_ambiguous
	elif [ -z "$HOOK_CWD" ]; then
		block_ambiguous
	else
		DIR="$HOOK_CWD"
	fi
fi

if [ -n "$DIR" ]; then
	GIT_CMD=(git -C "$DIR")
else
	GIT_CMD=(git)
fi

# skip pull when the current branch has no upstream tracking
# (typical for a first-time push of a new branch)
BRANCH=$("${GIT_CMD[@]}" branch --show-current || echo "")
if [ -n "$BRANCH" ]; then
	REMOTE=$("${GIT_CMD[@]}" config --get "branch.${BRANCH}.remote" || true)
	if [ -z "$REMOTE" ]; then
		exit 0
	fi
fi

# attempt pull --ff-only, capture combined output
if ! OUTPUT=$("${GIT_CMD[@]}" pull --ff-only 2>&1); then
	export OUTPUT
	python3 -c "
import json, os
reason = 'Pull --ff-only before push failed. Push blocked.\n\nGit output:\n' + os.environ.get('OUTPUT', '')
print(json.dumps({'decision': 'block', 'reason': reason}))
"
fi

exit 0
