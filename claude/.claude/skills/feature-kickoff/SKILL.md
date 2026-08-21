---
name: feature-kickoff
description: Walk through the research-verified full-stack feature workflow stage by stage before starting new feature work. Use when starting work on a new feature or ticket, or when asked to kick off / plan a feature.
---

# Feature kickoff

This is a conscious pause point, not an enforced gate (only PreToolUse hooks
can enforce - see git-branch-guard.sh for the git-level enforcement). That
means the only thing standing between this and being decoration is actually
producing visible output before code exists - a task named "run
feature-kickoff" that gets silently checked off with nothing shown to the
user is not this skill running, it is this skill being skipped while
claiming otherwise.

Hard requirement: print the plan block (see Output below) BEFORE writing or
editing any implementation file for this feature - not as a trailing
summary once the code already exists. If you have already started writing
code before running this, say so explicitly and produce the block now,
late, rather than skip it because the moment has passed.

Do not put "run feature-kickoff" on a task list as one item among others.
Invoke the Skill tool for feature-kickoff itself, and do so before creating
any task list or plan for this feature - not queued alongside implementation
tasks where it can be silently checked off without content. A task list
entry that says "kickoff" with nothing shown is the failure mode this
paragraph exists to prevent.

A sequencing question ("what should I build next", "which piece first") does
NOT satisfy stages 2, 3, 13, or 14 below, even if it happens to be about the
same feature. Those stages require a question about the content of the
design, the threats, or the deploy/rollout risk - not about the order of
work.

The stages below are NOT one flat timeline. They split into three groups by
when they can actually happen, and the PR gate is a boundary between the
first two, not stage N of a straight line:

- group A (before the PR): anything that is code or docs must land in the
  branch before you open the PR for review. Adding it after review has
  started means either it never gets reviewed, or you are pushing more
  commits into an already-open PR - worse practice, not better.
- the PR gate itself: everything in group A must already be in this diff.
- group B (after merge): these are deploy/operate concerns about the
  artifact the PR produced. They were never "in" the PR diff and do not
  belong there - trying to do them before merge does not make sense.

Run through the stages below in order within each group. For each one,
either confirm it applies and note how, or explicitly mark it skipped and
say why - never skip silently.

## Group A: before the PR - plan and design

1. Discover - read the ticket/issue, confirm acceptance criteria.
2. Design - sketch the API/schema before writing code. For anything more
   than a trivial shape, use AskUserQuestion to have the user pick or
   confirm the approach rather than deciding alone and mentioning it in
   passing - this is a judgment call the user should actually make.
3. Threat modeling - for anything touching auth, payments, secrets storage,
   or a new external surface. If it applies, use AskUserQuestion to walk
   the user through the real threats and get their call on scope, rather
   than silently reasoning through it and noting the conclusion. Skip for
   low-risk internal changes; do not skip by default, and do not downgrade
   an applicable case to a silent note because it felt obvious.
   The question must be about actual failure modes and tradeoffs specific
   to this feature, not a generic "sound good?" - for example, for
   biometric/keychain-backed auth: what happens when the biometric check
   is unavailable or fails (passcode fallback, or hard lock), is there a
   retry/lockout limit, how long does a decrypted key live in memory, does
   a failed unlock wipe anything. Pick the real ones for this feature - the
   point is specificity, not this exact list.
4. Architecture check - does this fit the existing layering (hexagonal:
   domain -> application -> infrastructure -> presentation)?

## Group A: before the PR - build

5. Branch and worktree - off develop, feat/fix/bug/chore/<slug>. Ask the
   user whether to work in an isolated worktree, per CLAUDE.md.
6. Implement, test-first - CONTESTED, not industry consensus (DHH's 2014
   test-induced-design-damage critique). Still the house rule per CLAUDE.md.
   If skipping test-first for a specific case, say so explicitly and why,
   rather than quietly writing implementation first.
7. Database migration safety - additive-first, rollback path decided before
   the deploy, not improvised after. The migration files themselves are
   code: they must be in this branch, not added once the PR is open.
8. Accessibility (WCAG AA) - CONTEXT-SCOPED: legally binding for regulated/
   public-sector surfaces, de facto best practice elsewhere. Applies if this
   touches user-facing frontend. The markup is code - same rule as above.
9. API versioning/deprecation - CONTEXT-SCOPED: applies once an API is
   versioned and has external consumers. Version routing/metadata is code.
10. Documentation - update API docs or architecture notes in the same
    branch, so a reviewer sees the doc change alongside the code change.
11. Self-review and CI gate - lint, typecheck, full test suite, dependency
    and secret scan, before a human looks at the diff.

## The PR gate

12. Pull request and human review. Confirm groups 1-11 are already in this
    diff before opening it - this is the checkpoint, not one item to knock
    out alongside the others.

## Group B: after merge - deploy and operate (never part of the PR diff)

13. Environment promotion - does this need a staging pass before prod?
    Unverified by the research behind this list either way. If a staging
    environment exists for this project and the change carries real risk
    (data migration, auth, payment, or anything hard to roll back cleanly),
    use AskUserQuestion to get the user's explicit call on staging vs
    direct-to-prod, rather than deciding alone and noting it in passing.
    For low-risk changes, or projects with no staging environment at all,
    use judgment and say so plainly - do not manufacture a question the
    project has no infrastructure to act on.
14. Feature flags / canary - does this change carry enough blast radius to
    ship behind a flag? Same caveat: unverified. If the project already has
    a feature-flag or canary system in place and this change has real blast
    radius (auth, billing, data migrations, or anything hitting all users
    at once), use AskUserQuestion to get the user's explicit call on
    flagging/canary vs a direct ship, rather than deciding alone. For
    low-blast-radius changes, or projects with no flag/canary system at
    all, use judgment and say so plainly - same rule as stage 13.
15. Observe - what will tell you this broke in production?
16. Blameless postmortem - only on an actual user-affecting incident, not
    every feature. Note it exists as a real stage, distinct from routine
    observability.

## Output

Before any implementation file for this feature is written or edited,
print a visible block in the conversation: which of stages 1-11 apply,
which were explicitly skipped and why, and the outcome of any
AskUserQuestion calls from stages 2/3. This block must actually appear in
the chat - a task-list entry that gets marked done with no corresponding
visible block means this did not run, regardless of intent.

At the PR gate (stage 12), and again after merge if group B stages come
up, repeat the same rule: say what applies and what's explicitly skipped,
visibly, not silently - including the outcome of any AskUserQuestion calls
from stages 13/14.
