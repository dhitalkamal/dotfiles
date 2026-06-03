#!/bin/bash
python3 -c "
import json, sys, subprocess

try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

ctx      = data.get('context_window') or {}
used_pct = round(ctx.get('used_percentage') or 0)
cost_usd = (data.get('cost') or {}).get('total_cost_usd') or 0
model    = ((data.get('model') or {}).get('display_name') or '').replace('Claude ', '').replace(' (1M context)', ' 1M')

try:
    branch = subprocess.check_output(
        ['git', 'branch', '--show-current'],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
except Exception:
    branch = ''

GREEN  = '\033[32m'
YELLOW = '\033[33m'
RED    = '\033[31m'
DIM    = '\033[2m'
RESET  = '\033[0m'

color = RED if used_pct >= 80 else YELLOW if used_pct >= 50 else GREEN

parts = [
    f'{color}ctx {used_pct}%{RESET}',
    f'{DIM}\${cost_usd:.4f}{RESET}',
]
if branch:
    parts.append(f' {branch}')
if model:
    parts.append(f'{DIM}{model}{RESET}')

print(' | '.join(parts))
"
