#!/usr/bin/env bash
# Restaura layout salvo (melhor esforço: move janelas por app_id).
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista/layouts"
PICKER="${HOME}/.config/scripts/picker.sh"
mkdir -p "$STATE"

DELETE=0
[[ "${1:-}" == "--delete" ]] && DELETE=1

mapfile -t FILES < <(find "$STATE" -maxdepth 1 -name '*.json' -printf '%f\n' | sort)
if [[ ${#FILES[@]} -eq 0 ]]; then
  notify-send "Layout" "Nenhum layout salvo"
  exit 0
fi

CHOICE=$(printf '%s\n' "${FILES[@]%.json}" | "$PICKER" -p "$([[ $DELETE -eq 1 ]] && echo Apagar || echo Restaurar)")
[[ -z "${CHOICE:-}" ]] && exit 0
FILE="$STATE/${CHOICE}.json"
[[ -f "$FILE" ]] || exit 1

if [[ $DELETE -eq 1 ]]; then
  rm -f "$FILE"
  notify-send "Layout" "Apagado: $CHOICE"
  exit 0
fi

python3 - "$FILE" <<'PY'
import json, subprocess, sys, time
from pathlib import Path

snap = json.loads(Path(sys.argv[1]).read_text())["windows"]

def sh(*args):
    try:
        subprocess.check_call(["niri", "msg", "action", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception:
        return False

def windows():
    return json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"], text=True))

live = windows()
used = set()

# Ordena por workspace e coluna
snap_sorted = sorted(snap, key=lambda s: (s.get("workspace_idx") or 0, s.get("column") or 0, s.get("row") or 0))

for s in snap_sorted:
    app = (s.get("app_id") or "").lower()
    if not app:
        continue
    match = None
    for w in live:
        if w["id"] in used:
            continue
        if (w.get("app_id") or "").lower() == app:
            match = w
            break
    if not match:
        continue
    used.add(match["id"])
    wid = str(match["id"])
    sh("focus-window", "--id", wid)
    time.sleep(0.05)
    idx = s.get("workspace_idx")
    if idx:
        sh("move-window-to-workspace", "--window-id", wid, str(idx))
        time.sleep(0.05)
        sh("focus-window", "--id", wid)
    col = s.get("column")
    if col:
        sh("move-column-to-index", str(int(col)))
        time.sleep(0.05)
    tw = s.get("tile_w")
    # Usa largura em pixels se disponível
    if tw and not s.get("floating"):
        sh("set-column-width", str(int(tw)))
    if s.get("floating") and not match.get("is_floating"):
        sh("toggle-window-floating")
    elif (not s.get("floating")) and match.get("is_floating"):
        sh("toggle-window-floating")

print(f"restored {len(used)} windows")
PY

if command -v dms >/dev/null; then
  dms ipc call toast info "Layout restaurado: ${CHOICE}" >/dev/null 2>&1 || true
fi
notify-send "Layout" "Restaurado: $CHOICE"
