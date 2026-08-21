---
paths:
  - "**/*.py"
  - "**/*.ts"
  - "**/*.go"
  - "**/*.java"
  - "**/*.rb"
---

# Architecture - hexagonal, always

Layers: domain -> application -> infrastructure -> presentation.
Imports flow inward only. Domain knows nothing outside itself.
One DB per service. Schema-per-domain.
