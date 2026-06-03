#!/bin/bash
set -euo pipefail

if [ "$PWD" = "$HOME" ] || [ "$PWD" = "/" ]; then
  exit 0
fi

[ ! -f "$PWD/CLAUDE.md" ] && exit 0

# already finalized for this repo
if [ -f "$PWD/.claude/.md-ready" ]; then
  exit 0
fi

python3 - << 'PYEOF'
import os, re, json, sys

cwd = os.getcwd()
claude_md = os.path.join(cwd, "CLAUDE.md")

with open(claude_md) as f:
    content = f.read()

has_pending = "<!-- md-status: pending-verification -->" in content
has_placeholders = bool(re.search(r'\[[^\]]+\](?!\()', content))

# state: verified (pending tag present, no placeholders left)
if has_pending and not has_placeholders:
    clean = content.replace("\n<!-- md-status: pending-verification -->\n", "\n")
    clean = clean.replace("<!-- md-status: pending-verification -->\n", "")
    clean = clean.replace("<!-- md-status: pending-verification -->", "")
    clean = clean.rstrip() + "\n"
    with open(claude_md, "w") as f:
        f.write(clean)

    marker_dir = os.path.join(cwd, ".claude")
    os.makedirs(marker_dir, exist_ok=True)
    with open(os.path.join(marker_dir, ".md-ready"), "w") as f:
        f.write("")

    print(json.dumps({
        "additionalContext":
            "CLAUDE.md verified and finalized for this repo. "
            "Marker written to .claude/.md-ready. "
            "This hook will skip this repo from now on."
    }))
    sys.exit(0)

# state: pending with remaining placeholders
if has_pending and has_placeholders:
    remaining = re.findall(r'\[[^\]]+\](?!\()', content)
    msg = "CLAUDE.md still has unfilled placeholders:\n"
    msg += "\n".join(f"  {p}" for p in remaining)
    msg += "\nFill these in, then the next session will finalize it."
    print(json.dumps({"additionalContext": msg}))
    sys.exit(0)

# no placeholders at all and no pending tag = not a template, skip
if not has_placeholders:
    sys.exit(0)

# state: first run (has placeholders, no pending tag)
project_name = os.path.basename(cwd)
exists = lambda p: os.path.exists(os.path.join(cwd, p))

# stack
has_manage = exists("manage.py")
has_pyproject = exists("pyproject.toml")
has_requirements = exists("requirements.txt")
has_pkg = exists("package.json")
has_ts = exists("tsconfig.json")

if has_manage:
    stack = "Python/Django"
elif has_pyproject or has_requirements:
    stack = "Python"
elif has_ts:
    stack = "Node/TS"
elif has_pkg:
    stack = "Node/JS"
else:
    stack = None

# db
db = None
schema = ""
for env_name in [".env", ".env.local", ".env.dev"]:
    env_path = os.path.join(cwd, env_name)
    if os.path.exists(env_path):
        try:
            with open(env_path) as f:
                for line in f:
                    if "DATABASE_URL" in line and "=" in line:
                        url = line.split("=", 1)[1].strip().strip("'\"")
                        if "postgres" in url:
                            db = "postgres"
                            parts = url.rsplit("/", 1)
                            if len(parts) > 1:
                                schema = parts[1].split("?")[0]
                        elif "mongo" in url:
                            db = "mongo"
                        break
        except (PermissionError, UnicodeDecodeError):
            pass
    if db:
        break

if not db:
    for dc in ["docker-compose.yml", "docker-compose.yaml", "compose.yml"]:
        if exists(dc):
            try:
                with open(os.path.join(cwd, dc)) as f:
                    dc_content = f.read()
                if "postgres" in dc_content:
                    db = "postgres"
                elif "mongo" in dc_content:
                    db = "mongo"
            except (PermissionError, UnicodeDecodeError):
                pass
            break

# queue
queue = "none"
for root, dirs, files in os.walk(cwd):
    depth = root.replace(cwd, "").count(os.sep)
    if depth > 2:
        dirs.clear()
        continue
    dirs[:] = [d for d in dirs if d not in (
        ".git", "node_modules", "__pycache__", ".venv", "venv"
    )]
    for fname in files:
        if fname in ("celery.py", "celeryconfig.py"):
            queue = "celery"
            break
    if queue != "none":
        break

if queue == "none" and has_pkg:
    try:
        with open(os.path.join(cwd, "package.json")) as f:
            if "bullmq" in f.read():
                queue = "bullmq"
    except (PermissionError, UnicodeDecodeError):
        pass

# tests
if has_manage or has_pyproject:
    tests = "uv run pytest"
elif has_pkg:
    tests = "yarn test"
else:
    tests = None

# lint
if has_pyproject or has_manage:
    lint = "uv run ruff check ."
elif has_pkg:
    lint = "yarn lint"
else:
    lint = None

# domain map
domain_dirs = []
for d in ["apps", "src", "app", "services", "modules"]:
    apps_dir = os.path.join(cwd, d)
    if os.path.isdir(apps_dir):
        for item in sorted(os.listdir(apps_dir)):
            item_path = os.path.join(apps_dir, item)
            if os.path.isdir(item_path) and not item.startswith((".", "_")):
                domain_dirs.append(item)
        break

# apply replacements
new = content
new = new.replace("[service name]", project_name)

if stack:
    new = re.sub(r'\[Python/Django \| Node/TS \| other\]', stack, new)

db_str = f"{db} -> {schema}" if db and schema else (db if db else None)
if db_str:
    new = re.sub(r'\[postgres \| mongo\] -> \[schema name\]', db_str, new)
    new = re.sub(r'\[postgres \| mongo\] → \[schema name\]', db_str, new)

new = re.sub(r'\[celery \| bullmq \| none\]', queue, new)

if tests:
    new = new.replace("uv run pytest | yarn test", tests)
if lint:
    new = new.replace("uv run ruff check . | yarn lint", lint)

if domain_dirs:
    domain_lines = "\n".join(f"# {d}" for d in domain_dirs)
    new = new.replace("# [domain] -> [what it owns]", domain_lines)
    new = new.replace("# [domain] → [what it owns]", domain_lines)

new = new.rstrip() + "\n\n<!-- md-status: pending-verification -->\n"

with open(claude_md, "w") as f:
    f.write(new)

# summary
inferred = []
manual = []

inferred.append(f"Project: {project_name}")
if stack:
    inferred.append(f"Stack: {stack}")
else:
    manual.append("Stack")
if db_str:
    inferred.append(f"DB: {db_str}")
else:
    manual.append("DB + schema")
inferred.append(f"Queue: {queue}")
if tests:
    inferred.append(f"Tests: {tests}")
else:
    manual.append("Tests")
if lint:
    inferred.append(f"Lint: {lint}")
else:
    manual.append("Lint")
if domain_dirs:
    inferred.append(f"Domain map: {', '.join(domain_dirs)}")
else:
    manual.append("Domain map")

msg = "Auto-filled CLAUDE.md from repo inspection:\n"
msg += "\n".join(f"  Inferred: {i}" for i in inferred)
if manual:
    msg += "\n\nStill needs manual input:\n"
    msg += "\n".join(f"  Unknown: {m}" for m in manual)
msg += "\n\nReview CLAUDE.md and correct any values."
msg += "\nOnce all [placeholders] are resolved, the next session finalizes it."

print(json.dumps({"additionalContext": msg}))
PYEOF
