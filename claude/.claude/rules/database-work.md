---
paths:
  - "**/migrations/**"
  - "**/models.py"
  - "**/*.sql"
  - "**/schema/**"
  - "**/*.prisma"
---

# Database work

Use the dbagent MCP tools for anything that touches a database:
querying, schema design, migrations, ops/tuning, observability,
vector search, or persistent memory. Do not write raw SQL or
reason about schema by hand when a dbagent tool covers it.
These servers are defined per project (for example
RecruitableATS/.mcp.json), not globally, and only load when the
session's working directory is inside that project. If a database
task comes up outside a project with dbagent configured, say so
instead of falling back to manual SQL.
