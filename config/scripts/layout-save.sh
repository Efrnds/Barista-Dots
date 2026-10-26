#!/usr/bin/env bash
# Salva layout das janelas niri (por app_id + workspace/coluna).
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista/layouts"
PICKER="${HOME}/.config/scripts/picker.sh"
mkdir -p "$STATE"

NAME=$(echo "" | "$PICKER" -p "Nome do layout" || true)
NAME=$(echo "$NAME" | tr -cd '[:alnum:] _.-' | xargs)
[[ -z "$NAME" ]] && NAME="default"
FILE="$STATE/${NAME}.json"

niri msg -j windows | python3 - "$FILE" <<'PY'
import json, sys
from pathlib import Path
windows = json.load(sys.stdin)
out = Path(sys.argv[1])
snap = []
for w in windows:
    lay = w.get("layout") or {}
    pos = lay.get("pos_in_scrolling_layout") or [None, None]
    tile = lay.get("tile_size") or [None, None]
    snap.append({
        "app_id": w.get("app_id") or "",
        "title": w.get("title") or "",
        "workspace_id": w.get("workspace_id"),
        "floating": bool(w.get("is_floating")),
        "column": pos[0],
        "row": pos[1],
        "tile_w": tile[0],
        "tile_h": tile[1],
    })
# map workspace_id -> idx
try:
    import subprocess
    wss = json.loads(subprocess.check_output(["niri","msg","-j","workspaces"], text=True))
    id_to_idx = {ws["id"]: ws["idx"] for ws in wss}
    for s in snap:
        s["workspace_idx"] = id_to_idx.get(s["workspace_id"])
except Exception:
    for s in snap:
        s["workspace_idx"] = None
out.write_text(json.dumps({"windows": snap}, indent=2) + "\n", encoding="utf-8")
print(out)
PY

if command -v dms >/dev/null; then
  dms ipc call toast info "Layout salvo: ${NAME}" >/dev/null 2>&1 || notify-send "Layout" "Salvo: $NAME"
else
  notify-send "Layout" "Salvo: $NAME"
fi
