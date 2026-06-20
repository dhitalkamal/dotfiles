#!/bin/bash
set -euo pipefail

# PreToolUse hook for Write|Edit.
# Counts every line in the resulting file content (blanks and comments included).
# Soft warning at 300 lines (printed to stderr, not blocking).
# Hard block at 500 lines.
# Exempts lock files, generated/minified files, and common build/migration dirs.

python3 -c "
import sys, json, os, fnmatch

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool = data.get('tool_name', '')
ti = data.get('tool_input', {})
file_path = ti.get('file_path', '')

if not file_path:
    sys.exit(0)

EXEMPT_BASENAMES = [
    '*.lock',
    '*-lock.json',
    'package-lock.json',
    'yarn.lock',
    'Pipfile.lock',
    'uv.lock',
    'Cargo.lock',
    'composer.lock',
    'Gemfile.lock',
    'go.sum',
    '*_pb2.py',
    '*_pb2_grpc.py',
    '*.pb.go',
    '*.generated.*',
    '*.gen.*',
    '*_generated.*',
    '*.codegen.*',
    '*.min.js',
    '*.min.css',
    '*.bundle.js',
    '*.bundle.css',
]

EXEMPT_DIRS = {
    'migrations',
    'node_modules',
    '__generated__',
    '.generated',
    'dist',
    'build',
    '.next',
    'out',
    'vendor',
}

basename = os.path.basename(file_path)
for pat in EXEMPT_BASENAMES:
    if fnmatch.fnmatch(basename, pat):
        sys.exit(0)

parts = set(file_path.split('/'))
if parts & EXEMPT_DIRS:
    sys.exit(0)

if tool == 'Write':
    content = ti.get('content', '')
elif tool == 'Edit':
    if not os.path.exists(file_path):
        sys.exit(0)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            current = f.read()
    except (UnicodeDecodeError, OSError):
        sys.exit(0)
    old_string = ti.get('old_string', '')
    new_string = ti.get('new_string', '')
    replace_all = ti.get('replace_all', False)
    if not old_string:
        sys.exit(0)
    if replace_all:
        content = current.replace(old_string, new_string)
    else:
        content = current.replace(old_string, new_string, 1)
else:
    sys.exit(0)

line_count = len(content.splitlines())

SOFT = 300
HARD = 500

if line_count >= HARD:
    msg = (
        f'File size limit exceeded: {line_count} lines (hard limit {HARD}). '
        f'Split this file into smaller modules. Path: {file_path}'
    )
    print(json.dumps({'decision': 'block', 'reason': msg}))
elif line_count >= SOFT:
    msg = (
        f'WARNING: file at {line_count} lines, over soft limit {SOFT}. '
        f'Hard limit is {HARD}. Consider splitting. Path: {file_path}'
    )
    print(msg, file=sys.stderr)
"
