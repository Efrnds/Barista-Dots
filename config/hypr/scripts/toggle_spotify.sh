#!/usr/bin/env bash
set -euo pipefail

SPECIAL="spotify"

if ! pgrep -xi "spotify" > /dev/null; then
    spotify &
    # Aguarda o processo iniciar e a window rule mover pro scratchpad
    sleep 0.5
fi

# Hyprland 0.56+ (config Lua): syntax antiga "togglespecialworkspace" não funciona mais
hyprctl dispatch 'hl.dsp.workspace.toggle_special("spotify")'
