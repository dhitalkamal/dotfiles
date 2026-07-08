name: nightly-pr-triage
schedule: daily 22:00 local
mode: routine

goal
====
run pr-review-toolkit review-pr against each open PR i authored,
capture findings, and store them so i can act in the morning.

scope
=====
- for each open PR authored by me, in each repo listed in
  ~/.claude/orchestration/state.json under "repos":
    - check out the PR branch in a git worktree.
    - run the review-pr skill.
    - store the review output at
      ~/.claude/logs/headless/pr-review-<repo>-<pr>-YYYY-MM-DD.md.
- do not post comments, do not merge, do not push.

constraints
===========
- skip any PR that already has a stored review from the last 24h.
- cap iterations at 10 PRs per run. log the rest as skipped.
- if a worktree fails to create, log and continue with the next PR.

output format
=============
one file per PR with sections:
  summary
  correctness
  style
  test-coverage
  suggested-follow-ups
