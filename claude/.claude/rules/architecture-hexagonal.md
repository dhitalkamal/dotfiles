---
paths:
  - "**/*.py"
  - "**/*.go"
  - "**/*.java"
  - "**/*.rb"
---

# Architecture - hexagonal, always

Backend services only - this describes service-level layering and
does not apply to frontend TypeScript (use the arch-style skill for
frontend/feature architecture decisions instead).

Layers: domain -> application -> infrastructure -> presentation.
Imports flow inward only. Domain knows nothing outside itself.
One DB per service. Schema-per-domain.
