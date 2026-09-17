#!/bin/bash
set -euo pipefail

# PreToolUse gate on Write|Edit|NotebookEdit. replacement for design-advisor-gate.sh.
#
# maps each gateable feature-kickoff step to (file pattern -> required local
# advisor) and BLOCKS the write until that advisor actually appears in the
# session transcript. this is the enforcing version of the old gate, which only
# reminded and never checked whether the advisor was really consulted.
#
# local advisors only - the remote foundry-* fleet (schema-designer, migration,
# etc.) lives on the homelab over tailscale and is dead whenever that host is off,
# so gating on it would trap the user. db-migration steps are therefore left as
# unenforced prose in the skill, on purpose. schema-design is gated below, but
# against the local db-design SKILL, not the remote MCP agent, for the same
# reason - never trap the user on a homelab dependency.
#
# structure placement/accessibility used to gate on the structure-advisor mcp
# server. that server was archived; the standalone arch-style skill replaces it.
# those two rules now require the arch-style skill instead, matched via the
# SKILL:<name> prefix form handled in the transcript check below.
#
# behavior per matched rule:
# - required advisor already in the transcript -> silent pass (exit 0)
# - not yet called -> permissionDecision "ask" naming the exact advisor
# safety valve: gives up after 2 asks per session (mirrors feature-workflow-gate
# and worktree-policy-gate) so a model that will not call the advisor is not trapped.
#
# priority when a path matches more than one rule: most specific first
# (endpoint > event-contract > frontend-accessibility > api-docs > generic new
# file placement), since the more specific advisor is the more useful one.
#
# promotion (human review gate): move this to ~/.claude/hooks/advisor-gate.sh,
# chmod +x. settings.json already points the PreToolUse Write|Edit|NotebookEdit
# block at this path, so no settings change is needed - just overwrite in place.

INPUT=$(cat)

# transcript + session are needed for the "was the advisor actually called" check
# and the safety-valve counter. bail quietly if the harness did not supply them.
TRANSCRIPT=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('transcript_path',''))" 2>/dev/null || echo "")
SESSION_ID=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null || echo "")

[ -z "$SESSION_ID" ] && exit 0
[ -z "$TRANSCRIPT" ] && exit 0
[ ! -f "$TRANSCRIPT" ] && exit 0

COUNTER_FILE="/tmp/.advisor-gate-count-${SESSION_ID}"
COUNT=0
[ -f "$COUNTER_FILE" ] && COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)

# safety valve: after 2 asks in this session, stop gating so nothing gets trapped
if [ "$COUNT" -ge 2 ]; then
	rm -f "$COUNTER_FILE"
	exit 0
fi

# all rule matching + the transcript check happen in python for clean pattern and
# json handling. it prints "ask <advisor> <reason>" on a block, or nothing on a pass.
RESULT=$(TRANSCRIPT_PATH="$TRANSCRIPT" python3 -c "
import sys, json, os, fnmatch

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, ValueError):
    sys.exit(0)

tool = data.get('tool_name', '')
ti = data.get('tool_input', {}) or {}
file_path = ti.get('file_path') or ti.get('notebook_path') or ''
if not file_path:
    sys.exit(0)

basename = os.path.basename(file_path)
parts = set(p for p in file_path.split('/') if p)

# ordered rules, most specific first. each: (matched, required advisor id, human
# reason). an advisor id is either an mcp tool prefix (mcp__...) or a skill in the
# form SKILL:<name>. schema and migration are intentionally absent - remote only.
def match_endpoint():
    return (
        basename in ('views.py', 'urls.py')
        or bool(parts & {'routes', 'controllers', 'endpoints'})
        or ('api' in parts and basename.endswith('.ts'))
    )

def match_event():
    return (
        bool(parts & {'events', 'kafka', 'topics'})
        or fnmatch.fnmatch(basename, '*producer*')
        or fnmatch.fnmatch(basename, '*consumer*')
        or basename.endswith(('.avsc', '.proto'))
    )

def match_frontend():
    return basename.endswith(('.tsx', '.jsx', '.vue', '.svelte', '.html'))

def match_apidocs():
    b = basename.lower()
    return b.startswith('openapi') or b.startswith('asyncapi')

def match_schema():
    return (
        basename in ('models.py', 'schema.prisma', 'schema.rb')
        or basename.endswith(('.model.ts', '.entity.ts'))
        or bool(parts & {'migrations', 'migrate'})
        or fnmatch.fnmatch(file_path, '*/alembic/versions/*.py')
    )

def match_newfile():
    # generic placement check only for brand-new files (Write to a missing path)
    return tool == 'Write' and not os.path.exists(file_path)

rules = [
    (match_endpoint(), 'mcp__endpoint-advisor__propose_api_design',
     'endpoint/route change - consult endpoint-advisor (propose_api_design)'),
    (match_event(), 'mcp__kafka-mcp__describe_topic',
     'event/topic change - consult kafka-mcp (describe_topic) for the contract'),
    (match_frontend(), 'SKILL:arch-style',
     'frontend markup - consult the arch-style skill for structure/accessibility'),
    (match_apidocs(), 'mcp__endpoint-advisor__generate_openapi_doc',
     'api spec doc - consult endpoint-advisor (generate_openapi_doc)'),
    (match_schema(), 'SKILL:db-design',
     'model/schema change - consult the db-design skill for design review (local, no MCP)'),
    (match_newfile(), 'SKILL:arch-style',
     'new file - consult the arch-style skill for correct placement'),
]

hit = next((r for r in rules if r[0]), None)
if hit is None:
    sys.exit(0)

_, advisor, reason = hit

# was this advisor already called this session? scan the transcript for a
# matching tool_use. two forms:
# - mcp tool: a tool_use whose name starts with the advisor prefix.
# - SKILL:<name>: a tool_use named 'Skill' whose input.skill equals <name>.
skill_name = advisor[len('SKILL:'):] if advisor.startswith('SKILL:') else None

def block_matches(block):
    if not (isinstance(block, dict) and block.get('type') == 'tool_use'):
        return False
    name = str(block.get('name', ''))
    if skill_name is not None:
        if name != 'Skill':
            return False
        binp = block.get('input', {}) or {}
        return binp.get('skill') == skill_name
    return name.startswith(advisor)

called = False
try:
    with open(os.environ['TRANSCRIPT_PATH']) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # cheap prefilter: the advisor token (or 'Skill') must be on the line
            token = 'Skill' if skill_name is not None else advisor
            if token not in line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            content = entry.get('message', {}).get('content', [])
            if not isinstance(content, list):
                continue
            if any(block_matches(b) for b in content):
                called = True
                break
except Exception:
    # if the transcript cannot be read, do not block - fail open
    sys.exit(0)

if called:
    sys.exit(0)

# emit a compact ask marker for the shell wrapper to turn into the hook decision
print('ASK\t' + advisor + '\t' + reason + ' (' + file_path + ')')
" <<<"$INPUT" || echo "")

# no marker -> nothing to gate (advisor already used, or no rule matched)
[ -z "$RESULT" ] && exit 0

REASON=$(printf '%s' "$RESULT" | cut -f3-)

# count this ask against the safety valve, then emit the PreToolUse decision
echo $((COUNT + 1)) > "$COUNTER_FILE"

REASON="$REASON" python3 -c "
import json, os
print(json.dumps({'hookSpecificOutput': {
    'hookEventName': 'PreToolUse',
    'permissionDecision': 'ask',
    'permissionDecisionReason': os.environ['REASON'] +
        ' - call the advisor first, or approve to proceed without it if this change does not need it.',
}}))
"
exit 0
