#!/usr/bin/env bash
# dmenu-style picker (fuzzel) — cores sincronizadas com DMS quando disponível
# Usage: echo -e "option1\noption2" | picker.sh [-p prompt]

set -euo pipefail

PROMPT="Escolha"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prompt) PROMPT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

DMS_COLORS="${XDG_CACHE_HOME:-$HOME/.cache}/DankMaterialShell/dms-colors.json"
FONT="ABC Areal Mono:size=11"

ARGS=(
  --dmenu
  --prompt="${PROMPT} > "
  --font="${FONT}"
  --width=48
  --lines=12
  --border-radius=14
  --border-width=1
  --inner-pad=8
  --layer=overlay
  --match-mode=fzf
  --counter
)

# Material palette do DMS → fuzzel (RRGGBBAA)
if [[ -f "$DMS_COLORS" ]]; then
  # shellcheck disable=SC2046
  eval $(python3 - "$DMS_COLORS" <<'PY'
import json, sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
c = data.get("colors", {}).get("dark") or data.get("colors", {}).get("light") or {}

def hx(key, fallback, alpha="ff"):
    v = (c.get(key) or fallback).lstrip("#")
    if len(v) == 6:
        v = v + alpha
    elif len(v) == 8:
        pass
    else:
        v = fallback.lstrip("#")
        if len(v) == 6:
            v = v + alpha
    return v.lower()

# fundo bem opaco; seleção / match no primary
bg = hx("surface_container", hx("background", "1a1110"), "f2")
fg = hx("on_surface", hx("on_background", "f1dedc"), "ff")
muted = hx("on_surface_variant", hx("outline", "6c5f5d"), "ff")
primary = hx("primary", "9c544b", "ff")
on_primary = hx("on_primary", "3c0a06", "ff")
sel = hx("secondary_container", hx("primary_container", "5f3f3a"), "ff")
border = hx("outline_variant", hx("outline", "564a48"), "cc")

print(f'BG={bg}')
print(f'FG={fg}')
print(f'MUTED={muted}')
print(f'PRIMARY={primary}')
print(f'ON_PRIMARY={on_primary}')
print(f'SEL={sel}')
print(f'BORDER={border}')
PY
)
  ARGS+=(
    --background-color="$BG"
    --text-color="$FG"
    --prompt-color="$PRIMARY"
    --input-color="$FG"
    --placeholder-color="$MUTED"
    --message-color="$FG"
    --match-color="$PRIMARY"
    --selection-color="$SEL"
    --selection-text-color="$FG"
    --selection-match-color="$PRIMARY"
    --counter-color="$MUTED"
    --border-color="$BORDER"
    --selection-radius=10
  )
fi

exec fuzzel "${ARGS[@]}"
