---
paths:
  - "**/*.py"
  - "pyproject.toml"
  - "manage.py"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "package.json"
---

# Package managers

Python: uv run for scripts. uv add for installing.
python manage.py for Django.
JS/TS: no global default - check the repo's lockfile (pnpm-lock.yaml,
yarn.lock, package-lock.json) or its CLAUDE.md before running any
package manager command. Never assume yarn.
Defer to project conventions when set. Check pyproject.toml or
package.json.
