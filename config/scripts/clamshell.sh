#!/usr/bin/env bash
# Clamshell: com monitor externo, fechar lid desliga eDP; senão só lock.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/barista"
MODE_FILE="${STATE_DIR}/clamshell"
mkdir -p "$STATE_DIR"
[[ -f "$MODE_FILE" ]] || echo on >"$MODE_FILE"

EDP="eDP-1"
toast() { dms ipc call toast info "$1" >/dev/null 2>&1 || notify-send "Clamshell" "$1"; }

external_connected() {
  niri msg -j outputs 2>/dev/null | python3 -c '
import json,sys
outs=json.load(sys.stdin)
items = outs.values() if isinstance(outs, dict) else outs
ext=0
for name,o in (outs.items() if isinstance(outs,dict) else [(o.get("name"),o) for o in items]):
    n = name or ""
    if str(n).startswith("eDP"):
        continue
    # logical=None => desligado; current_mode set => ativo
    if o.get("logical") is not None or o.get("current_mode") is not None:
        ext += 1
print(ext)
'
}

cmd="${1:-}"

case "$cmd" in
  close)
    mode=$(cat "$MODE_FILE" 2>/dev/null || echo on)
    ext=$(external_connected || echo 0)
    if [[ "$mode" == "on" && "${ext:-0}" -gt 0 ]]; then
      niri msg output "$EDP" off >/dev/null 2>&1 || true
      toast "Clamshell: eDP off (externo ativo)"
    else
      loginctl lock-session >/dev/null 2>&1 || true
    fi
    ;;
  open)
    niri msg output "$EDP" on >/dev/null 2>&1 || true
    # small delay then power on monitors
    niri msg action power-on-monitors >/dev/null 2>&1 || true
    ;;
  force-off-edp)
    niri msg output "$EDP" off
    toast "eDP desligado"
    ;;
  force-on-edp)
    niri msg output "$EDP" on
    toast "eDP ligado"
    ;;
  *)
    echo "uso: clamshell.sh {close|open|force-off-edp|force-on-edp}"
    exit 1
    ;;
esac
