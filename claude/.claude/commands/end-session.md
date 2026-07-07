---
description: Save context, sync memory, and archive outputs at session end
argument-hint: "[light|medium|full] (default medium)"
---

Run the session end protocol. This mirrors /start-session. Personal memory lives
at ~/agent/.memory. Pick a closure level from $ARGUMENTS, default medium.

Light:
1. Update ~/agent/.memory/session_hot_context.md: what is in progress, what
   decisions are pending. Set last_updated to today.

Medium (includes light, plus):
2. Process ~/agent/.memory/daily_note.md: route each item to memory, projects,
   or WAITING_ON_ME, then clear the processed items.
3. Update the entities and hypotheses files in ~/agent/.memory with anything
   learned this session.

Full (includes medium, plus):
4. Run /autolearn to extract structured learnings.
5. Copy any session outputs to ~/agent/Outbox/ and write a one-line daily summary.

After closing, report which level ran and what changed, in under 8 lines.
