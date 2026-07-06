name: weekly-deps-audit
schedule: weekly sunday 20:00 local
mode: routine

goal
====
audit outdated and vulnerable dependencies across active repos.

scope
=====
- for each repo listed in ~/.claude/orchestration/state.json:
    - detect stack from pyproject.toml or package.json.
    - python: run uv pip list --outdated.
    - js/ts: run yarn outdated.
    - collect security advisories via gh api if available.
- write a per-repo report to
  ~/.claude/logs/headless/deps-audit-<repo>-YYYY-MM-DD.md.
- do not install, upgrade, or open PRs.

constraints
===========
- pure read. any package manager write is a bug.
- respect the repos list. do not audit unlisted repos.

output format
=============
per-repo report sections:
  outdated-packages
  advisories
  suggested-upgrades (name, current, latest, breaking-risk)
