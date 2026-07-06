name: morning-brief
schedule: daily 07:00 local
mode: routine

goal
====
give a short digest of what needs attention today.

scope
=====
- list open PRs across my repos that are waiting on my review or on ci.
- list issues assigned to me that have new activity since yesterday.
- flag any failed workflow runs from the last 12 hours.
- write the output to ~/.claude/logs/headless/morning-brief-YYYY-MM-DD.md.
- do not modify code. do not open, close, comment on, or merge anything.

constraints
===========
- read-only. any write outside the log file is a bug.
- if gh is not authenticated, write a note in the log and exit.
- keep the digest under 60 lines.

output format
=============
sections in the log:
  prs-waiting-on-me
  prs-waiting-on-ci
  issues-with-new-activity
  failed-workflows
  suggested-focus (2-3 bullets)
