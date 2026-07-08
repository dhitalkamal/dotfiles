---
description: Load context, check queues, and report the delta at session start
---

Run the session start protocol. This mirrors /end-session. Personal memory lives
at ~/agent/.memory regardless of your current directory.

Steps:
1. Load ~/agent/.memory/MEMORY.md, then load
   ~/agent/.memory/session_hot_context.md. If its last_updated is more than 72
   hours old, treat it as stale and say so; do not present it as current.
2. Report the delta since last session in one short block:
   - anything in ~/agent/.memory/WAITING_ON_ME.md older than 7 days (nudge)
   - open hypotheses in ~/agent/.memory/hypotheses.md relevant to today
   - unprocessed items in ~/agent/.memory/daily_note.md
3. Surface red alerts only if present: blocked items, decisions pending too long.
   If nothing is pending, say "no open loops" and stop.
4. Do not ask what to work on. Present the state, then wait.

Keep the whole report under 12 lines. Pre-tool brevity applies.
