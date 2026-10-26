#!/usr/bin/env bash
# Layouts por contexto: coding | browse | save-<name>
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista/layouts"
RESTORE="${HOME}/.config/scripts/layout-restore.sh"
SAVE="${HOME}/.config/scripts/layout-save.sh"
mkdir -p "$STATE"

toast() {
  local m="$1"
  dms ipc call toast info "$m" >/dev/null 2>&1 || notify-send "Layout" "$m"
}

restore_named() {
  local name="$1"
  local file="$STATE/${name}.json"
  if [[ ! -f "$file" ]]; then
    toast "Layout '$name' ainda não existe — salve com: layout-context.sh save $name"
    exit 1
  fi
  # layout-restore usa picker; aqui restauramos direto
  python3 - "$file" <<'PY'
import json, subprocess, sys, time
from pathlib import Path

snap = json.loads(Path(sys.argv[1]).read_text())["windows"]

def action(*args):
    try:
        subprocess.check_call(["niri", "msg", "action", *args],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False

def windows():
    return json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"], text=True))

live = windows()
used = set()
snap_sorted = sorted(snap, key=lambda s: (s.get("workspace_idx") or 0, s.get("column") or 0, s.get("row") or 0))

for s in snap_sorted:
    app = s.get("app_id") or ""
    cand = None
    for w in live:
        wid = w.get("id")
        if wid in used:
            continue
        if (w.get("app_id") or "") == app:
            cand = w
            break
    if not cand:
        continue
    used.add(cand["id"])
    action("focus-window", "--id", str(cand["id"]))
    ws = s.get("workspace_idx")
    if ws:
        action("move-window-to-workspace", str(ws))
    if s.get("floating") and not cand.get("is_floating"):
        action("toggle-window-floating")
    elif (not s.get("floating")) and cand.get("is_floating"):
        action("toggle-window-floating")
    time.sleep(0.05)
PY
  toast "Layout: $name"
}

save_named() {
  local name="$1"
  # Reusa lógica do layout-save sem picker
  NAME=$(echo "$name" | tr -cd '[:alnum:] _.-' | xargs)
  [[ -z "$NAME" ]] && NAME="default"
  FILE="$STATE/${NAME}.json"
  niri msg -j windows | python3 - "$FILE" <<'PY'
import json, sys, subprocess
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
try:
    wss = json.loads(subprocess.check_output(["niri","msg","-j","workspaces"], text=True))
    id_to_idx = {ws["id"]: ws["idx"] for ws in wss}
    for s in snap:
        s["workspace_idx"] = id_to_idx.get(s["workspace_id"])
except Exception:
    pass
out.write_text(json.dumps({"windows": snap}, indent=2))
print(out)
PY
  toast "Salvo: $NAME"
}

case "${1:-}" in
  coding|browse) restore_named "$1" ;;
  save)
    shift
    save_named "${1:-default}"
    ;;
  save-coding) save_named coding ;;
  save-browse) save_named browse ;;
  *)
    echo "uso: $0 coding|browse|save-coding|save-browse|save <nome>" >&2
    exit 2
    ;;
esac
