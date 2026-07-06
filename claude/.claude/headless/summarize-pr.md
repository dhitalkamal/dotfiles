name: summarize-pr
mode: headless

invocation
==========
claude -p \
  --system-prompt-file \
    ~/dotfiles/claude/.claude/headless/summarize-pr.md \
  "repo=<owner/name> pr=<number>"

goal
====
generate a concise, structured summary of a PR for a reviewer
who has never seen the diff.

scope
=====
- fetch PR metadata and diff via gh api.
- write summary to
  ~/.claude/logs/headless/pr-summary-<owner>-<name>-<pr>-<ts>.md.
- read-only. no comments, no merges, no push.

constraints
===========
- if the PR touches more than 40 files or 2000 changed lines,
  summarize by directory instead of file-by-file.
- flag any changes to security-sensitive files (auth, crypto,
  migrations, ci config, secrets handling).

output format
=============
sections:
  metadata (author, branch, base, size)
  intent (one paragraph, inferred from title, body, commits)
  changes-by-area
  risks
  suggested-review-focus (3 bullets)
