#!/bin/bash
set -euo pipefail

# fires on `gh pr create`, checking two workflow stages that are otherwise
# easy to silently skip before opening a PR: documentation (stage 10) and
# self-review/CI gate (stage 11). both are asks, not denies - "does this
# need docs" and "did you actually run tests/lint/scans" are judgment
# calls the human should confirm, not things this script can verify with
# confidence on its own.
#
# stage 11 deliberately does not re-run the test suite itself: a full
# build+test cycle inside a synchronous PreToolUse hook risks being slow
# enough to time out or make `gh pr create` feel broken, especially for a
# compiled project, and there is no single command that reliably fits
# every project type. asking for an explicit confirmation is weaker than
# actually running the suite, but it is a real forced pause instead of one
# more silently-skippable task-list entry - see feature-kickoff/SKILL.md's
# own history: the same problem, attempted via instructions alone, failed
# live twice before landing on real AskUserQuestion requirements. this
# hook exists because "before a human looks at the diff" (stage 11) and
# "before opening it" (stage 12) are supposed to be unconditional, and
# nothing was actually enforcing that until now.
#
# 2026-08-17 fix: dir resolution used to grep -C out of the whole (possibly
# multi-line, multi-command) $CMD string via head -1, same root cause found
# in git-branch-guard.sh and pre-push-pull.sh - an unrelated -C on an
# earlier line in a batched command could resolve to the wrong repo. lower
# stakes here (worst case was "ask a slightly less specific question," never
# a silent skip or wrong hard block), but fixed for consistency: resolution
# is now scoped to the line(s) that actually contain `gh pr create`.

BASE_BRANCH_DEFAULT="develop"

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" || echo "")
HOOK_CWD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cwd',''))" || echo "")

[ -z "$CMD" ] && exit 0

echo "$CMD" | grep -qE '\bgh[[:space:]]+pr[[:space:]]+create\b' || exit 0

ask() {
	python3 -c "
import json, sys
print(json.dumps({'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'ask', 'permissionDecisionReason': sys.argv[1]}}))
" "$1"
	exit 0
}

# same resolution idiom as git-branch-guard.sh/pre-push-pull.sh, scoped to
# the line(s) that actually contain `gh pr create` - the consequence of a
# bad resolution here is only "ask a slightly less specific question," never
# a silent skip or a wrong hard block, so ambiguity folds into the generic
# combined ask below rather than a separate deny path.
resolve_dir() {
	local relevant
	local distinct
	local dir

	relevant=$(echo "$CMD" | grep -E '\bgh[[:space:]]+pr[[:space:]]+create\b' || true)
	[ -z "$relevant" ] && relevant="$CMD"

	distinct=$(echo "$relevant" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | sort -u | wc -l | tr -d ' ')
	if [ "$distinct" -gt 1 ]; then
		echo "AMBIGUOUS"
		return 0
	fi

	dir=$(echo "$relevant" | sed -nE 's/.*-C[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
	if [ -z "$dir" ]; then
		dir=$(echo "$relevant" | sed -nE 's/^[[:space:]]*cd[[:space:]]+([^[:space:]]+)[[:space:]]*&&.*/\1/p' | head -1)
	fi
	if [ -z "$dir" ]; then
		if echo "$CMD" | grep -qE '(^|[;&|])[[:space:]]*cd[[:space:]]'; then
			echo "AMBIGUOUS"
			return 0
		fi
		dir="$HOOK_CWD"
	fi
	case "$dir" in
		*'$'*) echo "AMBIGUOUS"; return 0 ;;
		"~") echo "$HOME" ;;
		"~/"*) echo "$HOME/${dir#\~/}" ;;
		*) echo "$dir" ;;
	esac
}

GENERIC_ASK="Before opening this PR:
- stage 10 (documentation): could not inspect this branch's diff to check for docs changes - confirm manually whether this needs a docs/architecture-notes update.
- stage 11 (self-review/CI gate): confirm lint, typecheck, the full test suite, and a dependency/secret scan have actually been run on this branch, not just that tests exist."

DIR=$(resolve_dir)
[ -z "$DIR" ] && DIR="AMBIGUOUS"
[ "$DIR" = "AMBIGUOUS" ] && ask "$GENERIC_ASK"

git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || ask "$GENERIC_ASK"

BASE=$(echo "$CMD" | sed -nE 's/.*--base[[:space:]]+([^[:space:]]+).*/\1/p' | head -1)
[ -z "$BASE" ] && BASE="$BASE_BRANCH_DEFAULT"

git -C "$DIR" rev-parse --verify "$BASE" >/dev/null 2>&1 || ask "$GENERIC_ASK"

CHANGED=$(git -C "$DIR" diff "$BASE"...HEAD --name-only 2>/dev/null || echo "")

DOC_MSG="stage 11 (self-review/CI gate): confirm lint, typecheck, the full test suite, and a dependency/secret scan have actually been run on this branch, not just that tests exist."

if [ -n "$CHANGED" ]; then
	CODE_FILES=$(echo "$CHANGED" | grep -icE '\.(swift|ts|tsx|js|jsx|py|go|rs|java|kt|rb|c|cpp|h|hpp|cs|m|mm)$' || true)
	DOC_FILES=$(echo "$CHANGED" | grep -icE '\.md$|(^|/)docs/' || true)
	if [ "$CODE_FILES" -ge 3 ] && [ "$DOC_FILES" -eq 0 ]; then
		ask "Before opening this PR:
- stage 10 (documentation): ${CODE_FILES} source file(s) changed on this branch with no documentation/architecture-notes changes alongside them - confirm this genuinely doesn't need one.
- ${DOC_MSG}"
	fi
fi

ask "Before opening this PR:
- ${DOC_MSG}"
