#!/usr/bin/env bash
# dmenu-style picker using fuzzel (Wayland-native)
# Drop-in replacement for the old eww picker.
# Usage: echo -e "option1\noption2" | picker.sh [-p prompt]

PROMPT="Escolha"
while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--prompt) PROMPT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

exec fuzzel --dmenu --prompt="$PROMPT > " \
    --font="JetBrainsMono Nerd Font:size=11" \
    --width=50 --lines=15 \
    --border-radius=12 \
    --layer=overlay
