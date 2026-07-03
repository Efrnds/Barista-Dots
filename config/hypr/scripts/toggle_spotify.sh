#!/bin/bash
if ! pgrep -xi "spotify" > /dev/null; then
    spotify &
    # Aguarda um pequeno momento para o processo iniciar
    sleep 0.2
fi
hyprctl dispatch togglespecialworkspace spotify
