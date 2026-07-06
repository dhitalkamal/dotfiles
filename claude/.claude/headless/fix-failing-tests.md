name: fix-failing-tests
mode: headless

invocation
==========
claude -p \
  --system-prompt-file \
    ~/dotfiles/claude/.claude/headless/fix-failing-tests.md \
  "repo=<absolute-path> branch=<branch-name>"

goal
====
open a worktree on the given branch, run the test suite, fix
failing tests one at a time using TDD discipline, and open a PR
with the fixes.

scope
=====
- inputs come from the entry prompt. no other assumptions.
- create a worktree branch fix/failing-tests-YYYYMMDD.
- run the test suite. capture output.
- for each failing test:
    - read the test to understand intent.
    - confirm the failure is real (not flaky) by running twice.
    - fix the smallest surface that makes it pass.
    - re-run the whole suite to confirm no regression.
- when all tests pass, open a PR against the input branch.
- write a run log to ~/.claude/logs/headless/fix-failing-tests-<ts>.md.

constraints
===========
- never push to main, master, or develop.
- never force push.
- never disable, skip, or delete tests to make them pass.
- if a failure looks flaky, log it and skip. do not paper over it.
- cap runtime at 45 minutes. checkpoint progress every 10 minutes.

output format
=============
run log sections:
  inputs
  initial-failures
  per-test-fix-log
  final-suite-result
  pr-url
