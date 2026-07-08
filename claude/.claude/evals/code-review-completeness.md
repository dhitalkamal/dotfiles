name: code-review-completeness
mode: eval-loop
max_iterations: 5

task
====
run pr-review-toolkit review-pr against a fixed corpus of PRs and
measure how many known issues the agent catches.

corpus
======
list of PR + expected-findings pairs lives at
~/dotfiles/claude/.claude/evals/corpus/code-review-completeness.jsonl
each line: {"pr": "owner/repo#num", "expected": ["finding-id-1", ...]}

metric
======
recall = matched_findings / expected_findings
precision = matched_findings / reported_findings
score = 2 * (recall * precision) / (recall + precision)   # f1

pass threshold
==============
score >= 0.8 on the corpus.

adjustment strategy
===================
each iteration, if score < threshold:
  - identify the finding categories that were missed most.
  - propose a refinement to the review-pr skill body (in
    ~/.claude/pending/skills/) that adds explicit checks for
    those categories.
  - do not modify the live skill. queue in pending/ for human review.
  - re-run the corpus after the proposed edit is applied by a human.

halt conditions
===============
- score >= threshold, or
- 5 iterations reached, or
- score fails to improve for 2 consecutive iterations.

output
======
per-iteration report at
~/.claude/logs/headless/eval-code-review-<ts>-iter-<n>.md
final report at
~/.claude/logs/headless/eval-code-review-<ts>-final.md
