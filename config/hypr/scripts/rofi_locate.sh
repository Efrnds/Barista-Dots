#!/bin/bash

# Busca rápida de arquivos no Home usando fd + Rofi

CHOSEN=$(fd --hidden --exclude .git --exclude node_modules --exclude .cache --type f . "$HOME" | \
    rofi -dmenu -p "🔍 Buscar arquivo" -i -theme-str "window {width: 50%;} listview {lines: 12;}")

if [ -n "$CHOSEN" ]; then
    xdg-open "$CHOSEN" &
fi
