#!/usr/bin/env bash
# Toggle system game mode: keep essentials for game + live, shed the rest.
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/obs-scene-router"
FLAG="$STATE_DIR/game-mode"
SNAPSHOT="$STATE_DIR/game-mode-snapshot.json"
DOCKER_LIST="$STATE_DIR/game-mode-docker-containers"
DOCKER_DAEMON_FLAG="$STATE_DIR/game-mode-stopped-docker-daemon"
ROUTER="${HOME}/.config/scripts/obs-scene-router/obs-scene-router.sh"

mkdir -p "$STATE_DIR"

notify() {
  notify-send -u low -t 2500 "Modo Jogo" "$1" 2>/dev/null || true
}

close_classes=(
  zen
  firefox
  firefox-esr
  chromium
  google-chrome
  brave-browser
  Cursor
  cursor
  code
  code-oss
  thunar
  org.gnome.Nautilus
  zapzap
  com.rtosta.zapzap
  zapfast
  ZapFast
  whatsapp
  WhatsApp
  whatsapp-desktop
  org.telegram.desktop
  telegram-desktop
  signal
  signal-desktop
  spotifast
  Spotifast
  SuperProductivity
  superproductivity
  mpv
)

is_on() { [[ -f "$FLAG" ]]; }

hypr_opt() {
  # usage: hypr_opt <option> <field>
  # field: int|bool|float|str
  local opt="$1" field="${2:-int}"
  hyprctl getoption "$opt" -j 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
f=sys.argv[1]
if f=='bool':
    print('true' if d.get('bool') else 'false')
elif f=='float':
    print(d.get('float', 1.0))
elif f=='str':
    print(d.get('str') or d.get('css') or '')
else:
    v=d.get('int', d.get('float', 0))
    print(int(v) if isinstance(v, float) and v==int(v) else v)
" "$field" 2>/dev/null
}

save_snapshot() {
  python3 - "$SNAPSHOT" <<'PY'
import json, os, subprocess, sys

path = sys.argv[1]

def sh(cmd):
    try:
        return subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def hypr(opt, field="int"):
    raw = sh(["hyprctl", "getoption", opt, "-j"])
    if not raw:
        return None
    d = json.loads(raw)
    if field == "bool":
        return bool(d.get("bool"))
    if field == "float":
        return float(d.get("float", 1.0))
    if field == "str":
        return d.get("str") or d.get("css") or ""
    v = d.get("int", d.get("float", 0))
    return int(v)

dnd = sh(["dms", "ipc", "call", "notifications", "getDoNotDisturb"]) or "false"
inhibit = sh(["dms", "ipc", "call", "inhibit", "status"]) or "disabled"
power = sh(["powerprofilesctl", "get"]) or "balanced"

snap = {
    "dnd": dnd.lower() == "true",
    "inhibit": inhibit,
    "powerprofile": power,
    "hypr": {
        "animations": hypr("animations:enabled", "bool"),
        "blur": hypr("decoration:blur:enabled", "bool"),
        "shadow": hypr("decoration:shadow:enabled", "bool"),
        "dim_inactive": hypr("decoration:dim_inactive", "bool"),
        "rounding": hypr("decoration:rounding", "int"),
        "inactive_opacity": hypr("decoration:inactive_opacity", "float"),
        "gaps_in": hypr("general:gaps_in", "int"),
        "gaps_out": hypr("general:gaps_out", "int"),
    },
    "dock_was_visible": True,
    "cliphist_was_running": bool(sh(["pgrep", "-f", "wl-paste --type text --watch cliphist store"])),
    "udiskie_was_running": bool(sh(["pgrep", "-x", "udiskie"])),
}

# gaps may be css multi-value on newer hypr; fall back parse
for gkey, opt in (("gaps_in", "general:gaps_in"), ("gaps_out", "general:gaps_out")):
    if snap["hypr"][gkey] in (None, 0):
        raw = sh(["hyprctl", "getoption", opt, "-j"])
        if raw:
            d = json.loads(raw)
            css = (d.get("css") or "").strip().split()
            if css:
                try:
                    snap["hypr"][gkey] = int(float(css[0]))
                except ValueError:
                    pass

with open(path, "w", encoding="utf-8") as f:
    json.dump(snap, f, indent=2)
    f.write("\n")
PY
}

apply_compositor_lite() {
  hyprctl --batch "\
keyword animations:enabled false;\
keyword decoration:blur:enabled false;\
keyword decoration:shadow:enabled false;\
keyword decoration:dim_inactive false;\
keyword decoration:rounding 0;\
keyword decoration:inactive_opacity 1.0;\
keyword general:gaps_in 0;\
keyword general:gaps_out 0" >/dev/null 2>&1 || true
  echo "[game-mode] compositor lite on"
}

restore_compositor() {
  [[ -f "$SNAPSHOT" ]] || return 0
  python3 - "$SNAPSHOT" <<'PY' | bash
import json, sys
s = json.load(open(sys.argv[1])).get("hypr", {})
def b(k, default=True):
    v = s.get(k, default)
    return "true" if v else "false"
cmds = [
    f"keyword animations:enabled {b('animations', True)}",
    f"keyword decoration:blur:enabled {b('blur', True)}",
    f"keyword decoration:shadow:enabled {b('shadow', True)}",
    f"keyword decoration:dim_inactive {b('dim_inactive', True)}",
    f"keyword decoration:rounding {int(s.get('rounding') or 14)}",
    f"keyword decoration:inactive_opacity {float(s.get('inactive_opacity') or 0.95)}",
    f"keyword general:gaps_in {int(s.get('gaps_in') or 6)}",
    f"keyword general:gaps_out {int(s.get('gaps_out') or 12)}",
]
print("hyprctl --batch \"" + ";".join(cmds) + "\" >/dev/null 2>&1 || true")
PY
  echo "[game-mode] compositor restored"
}

close_window_address() {
  local addr="$1"
  if hyprctl dispatch "hl.dsp.window.close({ window = \"address:${addr}\" })" >/dev/null 2>&1; then
    return 0
  fi
  hyprctl dispatch "hl.dsp.window.kill({ window = \"address:${addr}\" })" >/dev/null 2>&1 || true
}

close_nonessential_windows() {
  local cls addr closed=0
  local -A seen=()

  for cls in "${close_classes[@]}"; do
    while read -r addr; do
      [[ -z "$addr" || -n "${seen[$addr]:-}" ]] && continue
      seen["$addr"]=1
      close_window_address "$addr"
      closed=$((closed + 1))
      echo "[game-mode] closed address=${addr} class=${cls}"
    done < <(hyprctl clients -j | python3 -c "
import json, sys
target = sys.argv[1].lower()
for c in json.load(sys.stdin):
    cls = (c.get('class') or '')
    init = (c.get('initialClass') or '')
    if cls.lower() == target or init.lower() == target:
        print(c.get('address',''))
" "$cls" 2>/dev/null)
  done

  for cls in "${close_classes[@]}"; do
    hyprctl dispatch "hl.dsp.window.close({ window = \"class:${cls}\" })" >/dev/null 2>&1 || true
  done

  echo "[game-mode] closed_windows=${closed}"
}

stop_docker_stack() {
  rm -f "$DOCKER_LIST" "$DOCKER_DAEMON_FLAG"
  if ! command -v docker >/dev/null 2>&1; then
    echo "[game-mode] docker not installed; skip"
    return 0
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "[game-mode] docker daemon unavailable; skip"
    return 0
  fi

  docker ps --format '{{.Names}}' >"$DOCKER_LIST" 2>/dev/null || true
  if [[ -s "$DOCKER_LIST" ]]; then
    mapfile -t names <"$DOCKER_LIST"
    echo "[game-mode] stopping containers: ${names[*]}"
    docker stop "${names[@]}" >/dev/null 2>&1 || true
  else
    echo "[game-mode] no running docker containers"
  fi

  # Free dockerd/containerd RAM if polkit allows (no password).
  if systemctl is-active --quiet docker.service 2>/dev/null; then
    if systemctl stop docker.service >/dev/null 2>&1; then
      touch "$DOCKER_DAEMON_FLAG"
      echo "[game-mode] docker.service stopped"
    else
      echo "[game-mode] docker.service left running (no permission)"
    fi
  fi
}

restore_docker_stack() {
  if [[ -f "$DOCKER_DAEMON_FLAG" ]]; then
    systemctl start docker.service >/dev/null 2>&1 || true
    # wait until API is up
    for _ in $(seq 1 30); do
      docker info >/dev/null 2>&1 && break
      sleep 0.2
    done
    rm -f "$DOCKER_DAEMON_FLAG"
    echo "[game-mode] docker.service started"
  fi

  if [[ ! -s "$DOCKER_LIST" ]]; then
    rm -f "$DOCKER_LIST"
    return 0
  fi
  if ! command -v docker >/dev/null 2>&1; then
    return 0
  fi
  if ! docker info >/dev/null 2>&1; then
    echo "[game-mode] docker daemon unavailable; cannot restore containers"
    return 0
  fi

  mapfile -t names <"$DOCKER_LIST"
  echo "[game-mode] starting containers: ${names[*]}"
  docker start "${names[@]}" >/dev/null 2>&1 || true
  rm -f "$DOCKER_LIST"
}

stop_session_helpers() {
  if pgrep -f "wl-paste --type text --watch cliphist store" >/dev/null 2>&1 \
    || pgrep -f "wl-paste --type image --watch cliphist store" >/dev/null 2>&1; then
    pkill -f "wl-paste --type text --watch cliphist store" >/dev/null 2>&1 || true
    pkill -f "wl-paste --type image --watch cliphist store" >/dev/null 2>&1 || true
    echo "1" >"$STATE_DIR/game-mode-stopped-cliphist"
    echo "[game-mode] cliphist watchers stopped"
  else
    rm -f "$STATE_DIR/game-mode-stopped-cliphist"
  fi

  if pgrep -x udiskie >/dev/null 2>&1; then
    pkill -x udiskie >/dev/null 2>&1 || true
    echo "1" >"$STATE_DIR/game-mode-stopped-udiskie"
    echo "[game-mode] udiskie stopped"
  else
    rm -f "$STATE_DIR/game-mode-stopped-udiskie"
  fi

  dms ipc call dock hide >/dev/null 2>&1 || true
}

restore_session_helpers() {
  if [[ -f "$STATE_DIR/game-mode-stopped-cliphist" ]]; then
    wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
    disown || true
    wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
    disown || true
    rm -f "$STATE_DIR/game-mode-stopped-cliphist"
    echo "[game-mode] cliphist watchers restored"
  fi
  if [[ -f "$STATE_DIR/game-mode-stopped-udiskie" ]]; then
    udiskie >/dev/null 2>&1 &
    disown || true
    rm -f "$STATE_DIR/game-mode-stopped-udiskie"
    echo "[game-mode] udiskie restored"
  fi
  dms ipc call dock reveal >/dev/null 2>&1 || dms ipc call dock toggle >/dev/null 2>&1 || true
}

stop_background_noise() {
  if pgrep -f "ollama serve" >/dev/null 2>&1; then
    pkill -f "ollama serve" >/dev/null 2>&1 || true
    echo "1" >"$STATE_DIR/game-mode-stopped-ollama"
  else
    rm -f "$STATE_DIR/game-mode-stopped-ollama"
  fi

  if systemctl --user is-active --quiet rtk-dashboard.service 2>/dev/null; then
    systemctl --user stop rtk-dashboard.service >/dev/null 2>&1 || true
    echo "1" >"$STATE_DIR/game-mode-stopped-rtk"
  else
    rm -f "$STATE_DIR/game-mode-stopped-rtk"
  fi

  if systemctl --user is-active --quiet autoclean.service 2>/dev/null; then
    systemctl --user stop autoclean.service >/dev/null 2>&1 || true
    echo "1" >"$STATE_DIR/game-mode-stopped-autoclean"
  else
    rm -f "$STATE_DIR/game-mode-stopped-autoclean"
  fi

  stop_docker_stack
  stop_session_helpers

  # Optional system services — only if allowed without password.
  for svc in cups.service avahi-daemon.service; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      if systemctl stop "$svc" >/dev/null 2>&1; then
        echo "$svc" >>"$STATE_DIR/game-mode-stopped-system-svcs"
        echo "[game-mode] stopped $svc"
      fi
    fi
  done
  # WARP VPN overhead — skip if you need it mid-stream; restore on exit if we stopped it.
  if systemctl is-active --quiet warp-svc.service 2>/dev/null; then
    if systemctl stop warp-svc.service >/dev/null 2>&1; then
      echo "warp-svc.service" >>"$STATE_DIR/game-mode-stopped-system-svcs"
      echo "[game-mode] stopped warp-svc"
    fi
  fi
}

restore_background_noise() {
  if [[ -f "$STATE_DIR/game-mode-stopped-rtk" ]]; then
    systemctl --user start rtk-dashboard.service >/dev/null 2>&1 || true
    rm -f "$STATE_DIR/game-mode-stopped-rtk"
  fi
  if [[ -f "$STATE_DIR/game-mode-stopped-autoclean" ]]; then
    systemctl --user start autoclean.service >/dev/null 2>&1 || true
    rm -f "$STATE_DIR/game-mode-stopped-autoclean"
  fi
  rm -f "$STATE_DIR/game-mode-stopped-ollama"

  if [[ -f "$STATE_DIR/game-mode-stopped-system-svcs" ]]; then
    while read -r svc; do
      [[ -z "$svc" ]] && continue
      systemctl start "$svc" >/dev/null 2>&1 || true
      echo "[game-mode] restored $svc"
    done <"$STATE_DIR/game-mode-stopped-system-svcs"
    rm -f "$STATE_DIR/game-mode-stopped-system-svcs"
  fi

  restore_docker_stack
  restore_session_helpers
}

enable_game_mode() {
  rm -f "$STATE_DIR/game-mode-stopped-system-svcs"
  save_snapshot
  touch "$FLAG"

  systemctl --user start gamemoded.service >/dev/null 2>&1 || true
  dms ipc call notifications enableDoNotDisturbIndefinitely >/dev/null 2>&1 || true
  dms ipc call inhibit enable >/dev/null 2>&1 || true
  powerprofilesctl set performance >/dev/null 2>&1 || true

  apply_compositor_lite
  close_nonessential_windows
  stop_background_noise

  "$ROUTER" clear-force >/dev/null 2>&1 || true
  rm -f "$STATE_DIR/paused"
  "$ROUTER" force "Gameplay" >/dev/null 2>&1 || true
  sleep 0.2
  "$ROUTER" clear-force >/dev/null 2>&1 || true

  notify "ON — compositor lite + docker off + perf"
  echo "game-mode=on"
}

disable_game_mode() {
  rm -f "$FLAG"

  if [[ -f "$SNAPSHOT" ]]; then
    local dnd power
    dnd="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("dnd", False))' "$SNAPSHOT" 2>/dev/null || echo False)"
    power="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("powerprofile", "balanced"))' "$SNAPSHOT" 2>/dev/null || echo balanced)"
    if [[ "$dnd" == "True" || "$dnd" == "true" ]]; then
      dms ipc call notifications enableDoNotDisturbIndefinitely >/dev/null 2>&1 || true
    else
      dms ipc call notifications disableDoNotDisturb >/dev/null 2>&1 || true
    fi
    powerprofilesctl set "$power" >/dev/null 2>&1 || true
  else
    dms ipc call notifications disableDoNotDisturb >/dev/null 2>&1 || true
  fi

  restore_compositor
  dms ipc call inhibit disable >/dev/null 2>&1 || true
  restore_background_noise
  "$ROUTER" clear-force >/dev/null 2>&1 || true

  notify "OFF — tudo restaurado"
  echo "game-mode=off"
}

if is_on; then
  disable_game_mode
else
  enable_game_mode
fi
