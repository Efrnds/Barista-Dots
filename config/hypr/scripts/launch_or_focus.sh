#!/usr/bin/env bash
# Focus an existing window by class, or run a launch command.
set -euo pipefail

CLASS="${1:?window class required}"
shift

pick_address() {
    hyprctl clients -j | python3 -c "
import json, sys

target = sys.argv[1]
clients = [
    c for c in json.load(sys.stdin)
    if c.get('mapped')
    and (c.get('class') == target or c.get('initialClass') == target)
]
if not clients:
    sys.exit(1)

best = max(clients, key=lambda c: c['size'][0] * c['size'][1])
print(best['address'])
" "$CLASS"
}

if addr="$(pick_address 2>/dev/null)"; then
    if [[ -n "$addr" ]] && hyprctl dispatch "hl.dsp.focus({ window = \"address:${addr}\" })" >/dev/null 2>&1; then
        exit 0
    fi
fi

exec "$@"
