#!/usr/bin/env bash
# Scratchpad niri: esconde/mostra app no workspace nomeado "scratch".
# Usage: scratchpad.sh <term|music|notes>
set -euo pipefail

SLOT="${1:-term}"
SCRATCH_WS="scratch"

case "$SLOT" in
  term)
    APP_ID="scratch-term"
    SPAWN=(alacritty --class scratch-term)
    ;;
  music)
    APP_ID="spotifast"
    SPAWN=(spotifast)
    ;;
  notes)
    APP_ID="obsidian"
    SPAWN=(obsidian)
    ;;
  *)
    echo "usage: $0 term|music|notes" >&2
    exit 1
    ;;
esac

command -v niri >/dev/null || exit 1

mapfile -t INFO < <(niri msg -j windows | python3 -c '
import json,sys
app=sys.argv[1].lower()
wins=json.load(sys.stdin)
exact, soft = [], []
for w in wins:
    aid=(w.get("app_id") or "").lower()
    if aid == app: exact.append(w)
    elif app in aid: soft.append(w)
pick = exact[0] if exact else (soft[0] if soft else None)
if not pick:
    sys.exit(1)
print(pick["id"])
print(pick.get("workspace_id",""))
print(1 if pick.get("is_focused") else 0)
' "$APP_ID" 2>/dev/null || true)

CUR_WS="$(niri msg -j workspaces | python3 -c '
import json,sys
for w in json.load(sys.stdin):
    if w.get("is_focused"):
        # prefer name for named workspaces, else idx (focus-workspace accepts both)
        print(w["name"] if w.get("name") else w["idx"])
        break
')"

FOCUSED_WS_ID="$(niri msg -j workspaces | python3 -c '
import json,sys
for w in json.load(sys.stdin):
    if w.get("is_focused"):
        print(w["id"]); break
')"

if [[ ${#INFO[@]} -ge 2 ]]; then
  WIN_ID="${INFO[0]}"
  WIN_WS="${INFO[1]}"
  IS_FOCUSED="${INFO[2]:-0}"

  WIN_WS_NAME="$(niri msg -j workspaces | python3 -c '
import json,sys
wid=int(sys.argv[1])
for w in json.load(sys.stdin):
    if w.get("id")==wid:
        print(w.get("name") or "")
        break
' "$WIN_WS")"

  # Se está no scratch (ou não focado e está no scratch): traz pro workspace atual
  if [[ "$WIN_WS_NAME" == "$SCRATCH_WS" ]]; then
    niri msg action move-window-to-workspace --window-id "$WIN_ID" --focus true "$CUR_WS"
    niri msg action focus-window --id "$WIN_ID"
    exit 0
  fi

  # Se está no workspace focado (ou tem foco): esconde no scratch
  if [[ "$WIN_WS" == "$FOCUSED_WS_ID" || "$IS_FOCUSED" == "1" ]]; then
    niri msg action move-window-to-workspace --window-id "$WIN_ID" --focus false "$SCRATCH_WS"
    exit 0
  fi

  # Está em outro workspace: traz pra cá
  niri msg action move-window-to-workspace --window-id "$WIN_ID" --focus true "$CUR_WS"
  niri msg action focus-window --id "$WIN_ID"
  exit 0
fi

# Não existe: spawna
command -v "${SPAWN[0]}" >/dev/null || { echo "${SPAWN[0]} not found" >&2; exit 1; }
"${SPAWN[@]}" &
disown
