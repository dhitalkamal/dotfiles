#!/bin/bash
set -euo pipefail

# blocks git commit/push/merge against main, master, or develop, since the
# deny list in settings.json (git push --force*, git push -f *) only covers
# force pushes, not a plain push, commit, or merge against a protected
# branch - that gap needs the repo's actual current branch, which a static
# permission glob cannot see. settings.json's own allow list has
# "Bash(git merge *)" auto-approved with no branch awareness at all, so
# without this check a feature branch can be merged straight into develop,
# bypassing the PR/review gate entirely - confirmed live: every feature
# branch in a real test session merged straight into develop with zero
# friction, because merge was never covered here, only commit/push were.
#
# also soft-checks (ask, not block) that a commit's branch follows
# feat|fix|bug|chore/<slug>, since that is a personal convention, not a
# universal safety rule - a third-party repo may use its own naming scheme.
#
# reuses the -C/leading-cd/hook-cwd resolution idiom from pre-push-pull.sh so
# behavior stays consistent across the two scripts.
#
# dir/branch resolution is text-pattern matching on the raw command string,
# not real shell parsing - it cannot know what a `cd` on an earlier line, or
# a `cd "$VAR"`, actually resolves to at run time. live testing found this
# silently let protected-branch commits through in exactly those two forms,
# because the original version fell back to HOOK_CWD (the pre-cd directory,
# which is wrong, not just unknown) whenever it couldn't confidently resolve
# a literal path. this version fails SAFE instead: anything it cannot
# resolve with confidence is treated as AMBIGUOUS and denied with a message
# explaining how to make the command unambiguous, rather than silently
# skipping the check.
#
# 2026-08-17 fix: resolve_dir() used to grep -C out of the WHOLE (possibly
# multi-line, multi-command) $CMD string and take the first match via
# head -1, regardless of which line actually contained the operation being
# checked. found live: a batched setup script with an unrelated
# `git -C <other-repo> ...` line before the real commit/merge/push line
# caused this to resolve to the wrong repo entirely, denying a commit for
# the wrong reason (or worse, silently checking the wrong branch). now,
# resolution is restricted to the line(s) that actually contain the
# triggering subcommand (commit/merge/push), and if those lines disagree on
# more than one distinct -C target, that is AMBIGUOUS too, not "pick the
# first one and hope."

PROTECTED_RE='^(main|master|develop)$'
CONVENTION_RE='^(feat|fix|bug|chore)/'

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" || echo "")
HOOK_CWD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" || echo "")

[ -z "$CMD" ] && exit 0

deny() {
	python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': sys.argv[1]}}))
" "$1"
	exit 0
}

ask() {
	python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'ask', 'permissionDecisionReason': sys.argv[1]}}))
" "$1"
	exit 0
}

# resolve the repo dir for a specific operation keyword (commit/merge/push).
# explicit -C wins, then a same-line `cd <dir> &&`. resolution is scoped to
# only the line(s) containing the keyword, so an unrelated -C elsewhere in a
# batched multi-line command cannot be mistaken for this operation's target.
# if the relevant lines disagree on more than one distinct -C value, or
# anything else about the command can't be parsed with confidence, this
# returns the sentinel AMBIGUOUS instead of guessing.
resolve_dir() {
	local keyword="$1"
	local relevant
	local distinct
	local dir

	relevant=$(echo "$CMD" | grep -E "\bgit(\s+-C\s+\S+)?\s+${keyword}\b" || true)
	[ -z "$relevant" ] && relevant="$CMD"

	distinct=$(echo "$relevant" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | sort -u | wc -l | tr -d ' ')
	if [ "$distinct" -gt 1 ]; then
		echo "AMBIGUOUS"
		return 0
	fi

	dir=$(echo "$relevant" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
	if [ -n "$dir" ]; then
		case "$dir" in
			*'$'*) echo "AMBIGUOUS"; return 0 ;;
			*) echo "$dir"; return 0 ;;
		esac
	fi

	dir=$(echo "$relevant" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*&&.*/\1/p' | head -1)
	if [ -n "$dir" ]; then
		case "$dir" in
			*'$'*) echo "AMBIGUOUS"; return 0 ;;
			*) echo "$dir"; return 0 ;;
		esac
	fi

	if echo "$CMD" | grep -qE '(^|[;&|])[[:space:]]*cd[[:space:]]'; then
		echo "AMBIGUOUS"
		return 0
	fi

	if [ -z "$HOOK_CWD" ]; then
		echo "AMBIGUOUS"
		return 0
	fi

	echo "$HOOK_CWD"
}

current_branch() {
	local keyword="$1"
	local dir
	dir=$(resolve_dir "$keyword")
	if [ "$dir" = "AMBIGUOUS" ]; then
		echo "AMBIGUOUS"
		return 0
	fi
	git -C "$dir" branch --show-current 2>/dev/null || echo ""
}

# --- git commit: protected-branch hard block, naming-convention soft ask ---

if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+commit\b'; then
	BRANCH=$(current_branch "commit")
	if [ "$BRANCH" = "AMBIGUOUS" ]; then
		deny "commit blocked: could not safely determine the target repo/branch for this command (it changes directory via a shell variable, a separate line, another form this guard can't resolve as plain text, or multiple conflicting -C targets in the same batched command). retry as a single line with a literal absolute path, e.g. cd /abs/path && git commit ..., or git -C /abs/path commit ..."
	elif [ -n "$BRANCH" ]; then
		if echo "$BRANCH" | grep -qE "$PROTECTED_RE"; then
			deny "commit blocked: current branch is '${BRANCH}', a protected branch (main/master/develop). create a feat/fix/bug/chore branch off develop first."
		elif ! echo "$BRANCH" | grep -qE "$CONVENTION_RE"; then
			ask "current branch '${BRANCH}' does not follow feat/fix/bug/chore/<slug>. confirm this is intentional (e.g. a third-party repo with its own convention) before committing."
		fi
	fi
fi

# --- git merge: protected-branch hard block (merging INTO a protected branch) ---
#
# `git merge <other>` merges <other> INTO the current branch, so the current
# branch is the one being modified - same check as commit, reusing the same
# current_branch(). this correctly leaves merging THE OTHER WAY alone (e.g.
# `git checkout feat/x && git merge develop` to catch a feature branch up
# with develop) since the current branch there is feat/x, not a protected one.

if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+merge\b'; then
	BRANCH=$(current_branch "merge")
	if [ "$BRANCH" = "AMBIGUOUS" ]; then
		deny "merge blocked: could not safely determine the current branch for this merge (the command changes directory via a shell variable, a separate line, another form this guard can't resolve as plain text, or multiple conflicting -C targets in the same batched command). retry as a single line with a literal absolute path, e.g. cd /abs/path && git merge ..., or git -C /abs/path merge ..."
	elif [ -n "$BRANCH" ] && echo "$BRANCH" | grep -qE "$PROTECTED_RE"; then
		deny "merge blocked: current branch is '${BRANCH}', a protected branch (main/master/develop). merging a feature branch directly in bypasses the PR/review gate - open a pull request and merge through review instead."
	fi
fi

# --- git push: protected-branch hard block, explicit target or current branch ---

if echo "$CMD" | grep -qE '\bgit(\s+-C\s+\S+)?\s+push\b'; then
	# scope target extraction to the line(s) that actually contain the push,
	# same reasoning as resolve_dir() above - an unrelated colon-containing
	# or branch-looking token elsewhere in a batched command should not be
	# mistaken for this push's target.
	PUSH_LINES=$(echo "$CMD" | grep -E '\bgit(\s+-C\s+\S+)?\s+push\b' || true)
	[ -z "$PUSH_LINES" ] && PUSH_LINES="$CMD"

	# explicit refspec target: text after the last colon in a src:dst arg
	# (the `|| true` matters: under set -e/pipefail, grep -oE finding no
	# match returns 1, which would otherwise abort the whole script here
	# instead of just leaving TARGET empty for the fallbacks below)
	TARGET=$(echo "$PUSH_LINES" | grep -oE '[A-Za-z0-9._/-]+:[A-Za-z0-9._/-]+' | tail -1 | sed -E 's/.*://' || true)
	# otherwise, an explicit trailing branch arg: `git push <remote> <branch>`
	# (no \b here: BSD sed on macOS does not support it, unlike grep on this
	# system - see the \s note in pre-push-pull.sh for the same class of bug)
	if [ -z "$TARGET" ]; then
		TARGET=$(echo "$PUSH_LINES" | sed -nE 's/.*push[[:space:]]+(-[^[:space:]]+[[:space:]]+)*[A-Za-z0-9._-]+[[:space:]]+([A-Za-z0-9._/-]+).*/\2/p' | head -1)
	fi
	# no explicit target: push.default applies to the current branch
	if [ -z "$TARGET" ] || [ "$TARGET" = "HEAD" ]; then
		TARGET=$(current_branch "push")
	fi

	if [ "$TARGET" = "AMBIGUOUS" ]; then
		deny "push blocked: could not safely determine the current branch for this push (the command changes directory via a shell variable, a separate line, another form this guard can't resolve as plain text, or multiple conflicting -C targets in the same batched command). retry as a single line with a literal absolute path, or pass an explicit remote and branch."
	elif [ -n "$TARGET" ] && echo "$TARGET" | grep -qE "$PROTECTED_RE"; then
		deny "push blocked: target branch is '${TARGET}', a protected branch (main/master/develop). push a feat/fix/bug/chore branch and open a PR instead."
	fi
fi

exit 0
