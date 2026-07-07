---
description: Extract structured learnings from this session into memory
---

Scan this session and extract structured learnings into personal memory at
~/agent/.memory. This is extraction, not summarization. No prose recaps.

Extract into the correct memory files:
- new facts about people -> ~/agent/.memory/entities_people.md
- new facts about companies -> ~/agent/.memory/entities_companies.md
- new or updated hunches -> ~/agent/.memory/hypotheses.md (confidence and date)
- behavioral corrections from the principal ->
  ~/agent/.memory/user_behavioral_profile.md
- if the same correction has now happened more than 3 times, flag it: it belongs
  in the constitution (~/agent/CLAUDE.md) as a permanent rule, not just memory.

Rules:
- Update existing entries, do not duplicate.
- Only record what was actually observed this session.
- End by listing exactly what was added or changed, one line each.
