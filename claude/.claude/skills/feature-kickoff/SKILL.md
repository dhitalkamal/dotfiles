---
name: feature-kickoff
description: Walk through the research-verified full-stack feature workflow stage by stage before starting new feature work. Use when starting work on a new feature or ticket, or when asked to kick off / plan a feature.
---

# Feature kickoff

This is a conscious pause point, not an enforced gate (only PreToolUse hooks
can enforce - see git-branch-guard.sh for the git-level enforcement, and
advisor-gate.sh for the mcp-advisor enforcement). That means the only thing
standing between this and being decoration is actually producing visible output
before code exists - a task named "run feature-kickoff" that gets silently
checked off with nothing shown to the user is not this skill running, it is this
skill being skipped while claiming otherwise.

Hard requirement: print the plan block (see Output below) BEFORE writing or
editing any implementation file for this feature - not as a trailing summary
once the code already exists. If you have already started writing code before
running this, say so explicitly and produce the block now, late, rather than
skip it because the moment has passed.

Do not put "run feature-kickoff" on a task list as one item among others.
Invoke the Skill tool for feature-kickoff itself, and do so before creating any
task list or plan for this feature - not queued alongside implementation tasks
where it can be silently checked off without content. A task list entry that
says "kickoff" with nothing shown is the failure mode this paragraph exists to
prevent.

A sequencing question ("what should I build next", "which piece first") does NOT
satisfy stages 2, 3, 9, 10, 16, or 17 below, even if it happens to be about the
same feature. Those stages require a question about the content of the design,
the threats, the rollout, or the deploy/operate risk - not about the order of
work.

## Phase 0: classify the request first

Before walking any stages, classify the request out loud in one line so the user
can override you - "this looks bounded, so I will run the applicable DECIDE
stages and a short plan block, not the full architectural walk." The ceremony
scales with the task; the plan-before-code gate never does.

- spike - a feasibility probe ("can we", "is it possible", "quick and dirty is
  fine") whose output is an answer, not code you keep. Say what you will try in a
  sentence or two, get a nod, then find out as cheaply as correctness allows. No
  stage walk, no plan block beyond naming it a spike. Anything you build is
  labeled throwaway - keeping spike code is a new request, reclassify it.
- bounded - a well-scoped change to a flow that ALREADY EXISTS in this repo: a
  new flag, a small endpoint, a one-file fix. Bounded measures the repo, not your
  familiarity - if there is no existing flow to read and change, it is not
  bounded. Run only the DECIDE stages that actually apply (usually 1, 2, and any
  context-scoped stage that fires), print the short plan block, and stop for
  approval before code.
- architectural - new project, new service/app/aggregate, a new external surface,
  or a change that restructures how components fit or alters an interface others
  depend on. Run the full DECIDE walk below and use feature-architect for the
  placement/endpoint/schema stages.

One-way ratchet: when unsure between two paths, take the heavier one. Hidden
complexity discovered mid-task upgrades the path - stop, say so, step up. Nothing
downgrades mid-task. "I understand this kind of app" is not bounded; "it is
almost done" does not skip the upgrade.

The stage walk below (Phase 1 onward) is the architectural path in full. Bounded
runs the applicable subset; spike skips it.

## Which skill does which stage

feature-kickoff is the checklist, not the worker. Several stages below hand off
to a dedicated skill instead of reasoning inline - invoke it, do not reinvent
its logic in prose:

| Stage | Skill | Role |
|---|---|---|
| 2-10 (placement, endpoint, schema, threat model, etc.) | feature-architect | Decides the shape from a confirmed scope. Always the DECIDE-stage owner - the other API/schema skills below only run after this decision exists. |
| 2, CONTEXT-SCOPED: new public API surface or 3+ endpoints changed | api-designer | Produces the formal OpenAPI 3.1 spec once feature-architect's shape is confirmed - artifact generation, not the decision itself. Skip for a single small/internal endpoint; feature-architect's sketch is enough there. |
| 2, CONTEXT-SCOPED: 3+ new/changed tables or a new bounded context's schema | database-schema-designer | Produces the formal ERD + migration scripts once feature-architect's shape is confirmed - artifact generation, not the decision itself. Skip for a one-column/one-table change. |
| 4 (architecture fit), 7/12 (migration/implement) | arch-style, db-design (both automatic) | Fired by the design-advisor-gate hook the instant a file is actually created/edited in BUILD - a later, write-time audit of the artifact, not a substitute for the stage-4/7 decision and not a duplicate of the two rows above. Do not manually re-invoke them; the hook already owns that moment. |
| 11 (branch and worktree) | new-branch | Generates the actual feat/fix/bug/chore/<epic>/<task-name> name per the branching strategy, instead of leaving the pattern as a note. |
| 12 (implement, test-first) | tdd | The actual red-green-refactor mechanism enforcing the CLAUDE.md TDD rule - detects the project's test runner and runs the cycle, rather than this checklist re-describing TDD philosophy. |
| 14 (self-review and CI gate) | security-review, verify, webapp-qa (UI features only) | security-review covers the dependency/secret scan; verify covers "prove it actually works end-to-end" (the CLAUDE.md "prove it before done" rule); webapp-qa covers a real-browser pass for user-facing frontend changes. |

Four skills, four distinct jobs, no overlap: feature-architect decides, api-designer/
database-schema-designer draft the formal artifact for a significant surface,
arch-style/db-design audit the artifact automatically once it exists on disk.

## The three phases: decide, build, operate

The stages split into three phases by WHEN a thing can actually happen, not by
topic. The split is deliberate: every stage is either a decision that shapes
code, an artifact that is code, or an operation on the running system - and
conflating them is what lets contract decisions get made after the code they
were supposed to shape is already written.

- phase 1 DECIDE (before any implementation code): every decision that shapes
  what gets built. Settle these first. Writing code before they are settled
  means retrofitting the decision to the code instead of the other way round.
  Many of these decisions are a real AskUserQuestion, not a silent note.
- phase 2 BUILD (in the PR branch): every artifact and code change. Each build
  stage implements decisions made in DECIDE. Anything that is code or docs must
  land in the branch before the PR opens - adding it after review starts means
  it never gets reviewed, or you are stacking commits onto an open PR.
- the PR gate: everything in DECIDE and BUILD is already in this diff.
- phase 3 OPERATE (after merge): deploy and run concerns about the artifact the
  PR produced. They were never in the PR diff and do not belong there.

Some concerns span phases: a feature flag is a DECIDE (ship behind a flag?), a
BUILD (the flag wiring, which is code), and an OPERATE (the rollout). Same for
observability: decide the signals, build the instrumentation, operate the
alerts. Follow the split - do not collapse them back into one late stage.

Run through the stages in order within each phase. For each one, either confirm
it applies and note how, or explicitly mark it skipped and say why - never skip
silently.

## Phase 1: DECIDE - before any implementation code

For deep placement, endpoint, and schema advice on stages 2-10 (the
"new App or new Aggregate?" call, endpoint shape, data model), use the
feature-architect skill - it owns the same stage numbers and reference
docs. This checklist decides that each stage applies; feature-architect
works the hard ones in detail.

1. Discover - read the ticket/issue, confirm acceptance criteria.
2. API / schema design - sketch the API/schema shape before writing code. For
   anything more than a trivial shape, use AskUserQuestion to have the user pick
   or confirm the approach rather than deciding alone and mentioning it in
   passing - this is a judgment call the user should actually make.
   CONTEXT-SCOPED, event-driven/microservice work: also decide -
   - sync vs async per interaction (REST/gRPC vs a Kafka event).
   - data-consistency strategy: default is outbox pattern (DB write + event)
     plus choreography (services react to events, no coordinator).
     ON HOLD - saga: listed as an option, not used by default. Do not stand up
     saga/orchestration (e.g. Temporal) unless the user explicitly asks for it
     for this feature. Keep it here so it is ready to pull in the moment it is
     actually needed, not something to reach for on your own judgment.
   CONTEXT-SCOPED, new public API surface or 3+ endpoints changed: once
   feature-architect's shape is confirmed, use api-designer to produce the
   formal OpenAPI 3.1 spec (committed in stage 13). Skip for a single small or
   internal-only endpoint - feature-architect's sketch already covers it.
   CONTEXT-SCOPED, 3+ new/changed tables or a new bounded context's initial
   schema: once feature-architect's shape is confirmed, use
   database-schema-designer to produce the formal ERD and migration script
   artifact (committed alongside the migration files in stage 12). Skip for a
   one-column/one-table change.
3. Threat modeling - for anything touching auth, payments, secrets storage,
   personal data (PII), or a new external surface. If it applies, use
   AskUserQuestion to walk the user through the real threats and get their call
   on scope, rather than silently reasoning through it and noting the
   conclusion. Skip for low-risk internal changes; do not skip by default, and
   do not downgrade an applicable case to a silent note because it felt obvious.
   The question must be about actual failure modes and tradeoffs specific to
   this feature, not a generic "sound good?" - for example, for biometric/
   keychain-backed auth: what happens when the biometric check is unavailable or
   fails (passcode fallback, or hard lock), is there a retry/lockout limit, how
   long does a decrypted key live in memory, does a failed unlock wipe anything.
   Pick the real ones for this feature - the point is specificity.
   CONTEXT-SCOPED, consumer product touching personal data: also cover data
   classification, retention period, and the GDPR/deletion path as part of the
   same AskUserQuestion pass.
4. Architecture fit - does this fit the existing layering (hexagonal: domain ->
   application -> infrastructure -> presentation)?
   CONTEXT-SCOPED, event-driven/microservice work: also check -
   - database-per-service (no cross-service DB reads).
   - resilience defaults on sync calls: timeouts, retries with backoff, circuit
     breaker.
   Note: the arch-style skill re-audits this automatically at write time, fired
   by the design-advisor-gate hook the moment a new file is actually created in
   BUILD (stage 12). That is a second, later checkpoint, not a substitute for
   this decision - do not skip this stage because arch-style will "catch it
   later," and do not manually re-invoke arch-style here, the hook already owns
   that moment.
5. Event-contract decision - CONTEXT-SCOPED: does this feature emit or consume
   Kafka events?
   - NO - skip, rejoin at stage 6.
   - YES - decide the contract before implementation: topic name, partition key,
     schema shape (Avro/Protobuf for the Schema Registry), delivery guarantee,
     and DLQ. This is the up-front decision; the schema artifact and the
     producer/consumer code are written in BUILD (stage 12), not here.
6. API versioning decision - CONTEXT-SCOPED: applies once an API is versioned
   and has external consumers. Decide whether this change is breaking, the
   version strategy, and the deprecation policy. The routing/metadata is code
   and is written in BUILD (stage 12).
7. DB migration strategy - decide additive-first and the rollback path before
   the deploy, not improvised after. This is the decision; the migration files
   themselves are code and are written in BUILD (stage 12).
   Note: the db-design skill re-reviews the actual migration file automatically
   at write time, fired by the design-advisor-gate hook. Same relationship as
   stage 4 above - a later, write-time checkpoint, not a substitute for
   deciding the strategy now.
8. Accessibility scope - CONTEXT-SCOPED: legally binding for regulated/
   public-sector surfaces, de facto best practice elsewhere. Applies if this
   touches user-facing frontend. Decide the WCAG AA targets and which criteria
   apply. The accessible markup is code and is written in BUILD (stage 12).
9. Feature-flag decision - CONTEXT-SCOPED: applies if the project has a
   feature-flag/canary system AND this change has real blast radius (auth,
   billing, data migrations, or anything hitting all users at once). Decide
   whether to ship behind a flag, via AskUserQuestion. This is a DECIDE stage,
   not a post-merge one, because the flag wiring is code that must be in the PR
   (BUILD, stage 12); the rollout itself is OPERATE (stage 17). For low-blast-
   radius changes, or projects with no flag system, use judgment and say so
   plainly - do not manufacture a question the project cannot act on.
10. Observability plan - what will tell you this broke in production? Decide the
    signals now; the instrumentation is code written in BUILD (stage 12), and
    the dashboards/alerts are stood up in OPERATE (stage 18).
    CONTEXT-SCOPED, event-driven/microservice work: plan distributed tracing,
    consumer-lag monitoring, and DLQ-depth alerts.

## Phase 2: BUILD - in the PR branch

11. Branch and worktree - off develop, feat/fix/bug/chore/<slug>. Ask the user
    whether to work in an isolated worktree, per CLAUDE.md. Use the new-branch
    skill to generate the actual name (feat/fix/hotfix/bug/chore/<epic>/
    <task-name>) and its base ref, rather than improvising the slug.
12. Implement, test-first - CONTESTED, not industry consensus (DHH's 2014
    test-induced-design-damage critique). Still the house rule per CLAUDE.md. If
    skipping test-first for a specific case, say so explicitly and why, rather
    than quietly writing implementation first. Invoke the tdd skill to run the
    actual red-green-refactor cycle - it detects the project's test runner and
    enforces watch-it-fail-first; do not narrate the cycle inline instead of
    running it.
    This stage writes the artifacts for the decisions made in DECIDE: the event
    schema plus producer/consumer code (stage 5), version routing/metadata
    (stage 6), migration files (stage 7), accessible markup (stage 8), flag
    wiring (stage 9), and instrumentation (stage 10).
    CONTEXT-SCOPED, event-driven/microservice work: also cover -
    - consumer idempotency (dedup on at-least-once delivery).
    - producer-side idempotence config (enable.idempotence=true, acks=all)
      alongside the consumer dedup above - stops broker-level duplicate delivery
      before it ever reaches a consumer.
    - correlation ID propagation across service/event boundaries.
    - ON HOLD - contract tests (consumer-driven): listed as an option, not used
      by default. Rely on the stage-14 schema backward-compatibility check
      instead. Do not add consumer-driven contract tests unless the user
      explicitly asks for them for this feature.
13. Documentation - update API docs or architecture notes in the same branch, so
    a reviewer sees the doc change alongside the code change.
    CONTEXT-SCOPED, event-driven/microservice work: also document event/topic
    schemas (AsyncAPI), not just OpenAPI.
14. Self-review and CI gate - lint, typecheck, full test suite, dependency and
    secret scan, before a human looks at the diff. Use the security-review
    skill for the dependency/secret scan, and the verify skill to actually
    exercise the changed flow end-to-end rather than assuming the test suite
    passing means the feature works (the CLAUDE.md "prove it before done"
    rule). CONTEXT-SCOPED, user-facing frontend: also run webapp-qa for a
    real-browser pass over the changed flow before opening the PR.
    One concern, small diff - flag it before opening the PR if this diff bundles
    more than one unrelated concern or has grown past what a reviewer can
    reasonably hold in their head at once. State this as a real gate, not
    unwritten convention.
    CONTEXT-SCOPED, event-driven/microservice work: also run a schema backward-
    compatibility check. Contract tests from stage 12 only apply here if the
    user has explicitly opted into them - the default is the schema check alone.

## The PR gate

15. Pull request and human review. Confirm every DECIDE and BUILD stage is
    already in this diff before opening it - this is the checkpoint, not one item
    to knock out alongside the others.

## Phase 3: OPERATE - after merge, never part of the PR diff

16. Environment promotion - does this need a staging pass before prod?
    Unverified by the research behind this list either way. If a staging
    environment exists for this project and the change carries real risk (data
    migration, auth, payment, or anything hard to roll back cleanly), use
    AskUserQuestion to get the user's explicit call on staging vs
    direct-to-prod, rather than deciding alone and noting it in passing. For
    low-risk changes, or projects with no staging environment, use judgment and
    say so plainly - do not manufacture a question the project cannot act on.
17. Canary / flag rollout - operate the flag decided in stage 9. If the change
    has real blast radius and a canary system exists, use AskUserQuestion to get
    the user's explicit call on the rollout (canary vs flip-to-all), rather than
    deciding alone. Skip if stage 9 decided no flag.
18. Observe in production - stand up the dashboards and alerts for the plan from
    stage 10; confirm the instrumentation built in stage 12 is actually
    reporting.
    CONTEXT-SCOPED, event-driven/microservice work: distributed tracing,
    consumer-lag monitoring, and DLQ-depth alerts.
19. Blameless postmortem - only on an actual user-affecting incident, not every
    feature. Note it exists as a real stage, distinct from routine
    observability.

## Event-driven / microservice work: start-small priority

If phasing an event-driven or microservice addition instead of doing all of the
above at once, order the phases this way:

1. Outbox pattern (stage 2) plus consumer and producer idempotency (stage 12) -
   the correctness floor. Without these, nothing downstream is trustworthy.
2. The event-contract decision (stage 5) - forces the schema, partition key,
   delivery guarantee, and DLQ decisions up front instead of retrofitting them.
3. Distributed tracing and consumer-lag monitoring (planned in stage 10, stood
   up in stage 18) - the primary production signals for this class of change.

Consumer-driven contract tests and saga orchestration are ON HOLD, not in this
priority list by default - see stages 2 and 12 above. Both stay available as
options the moment the user explicitly asks for either one; neither is something
to add on your own judgment.

## Output: the plan block (blocking exit contract)

Before any implementation file for this feature is written or edited, print a
visible block in the conversation. This is a hard gate, not a trailing summary:
no implementation edit until the block exists in chat.

The block MUST use this exact shape, and its FINAL line MUST be the sentinel so
the block is unambiguously complete with nothing after it:

## Feature kickoff plan
Path: spike | bounded | architectural
Applied: <stage numbers, each with a one-line how>
Skipped: <stage numbers, each with why>
AskUserQuestion outcomes: <stage: decision, for 2/3/9 and any other applicable>
Plan doc: <path committed by feature-architect step 5, or "none - bounded/spike">
KICKOFF COMPLETE

Pre-code self-check - every item must be true before the first implementation
edit. If any fails, do the missing work; do not start code:
- [ ] the block above is visible in this conversation, not just on a task list
- [ ] path is classified and announced
- [ ] every applicable DECIDE stage is applied-with-how or skipped-with-why (none silent)
- [ ] AskUserQuestion outcomes recorded for every applicable 2/3/9
- [ ] the terminal line is exactly KICKOFF COMPLETE

A spike prints a one-line block instead: "Path: spike - <probe>; output is an
answer, not code" followed by KICKOFF COMPLETE. A task-list entry marked done
with no visible block means this did not run, regardless of intent.

At the PR gate (stage 15), and again after merge for the OPERATE stages, repeat
the same rule: say what applies and what is explicitly skipped, visibly, not
silently - including the outcome of any AskUserQuestion calls from stages 16/17.
