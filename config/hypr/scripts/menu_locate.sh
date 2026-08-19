#!/bin/bash

# Busca rápida de arquivos no Home usando fd + EWW picker

PICKER="$HOME/.config/hypr/scripts/picker.sh"

CHOSEN=$(fd --hidden --exclude .git --exclude node_modules --exclude .cache --type f . "$HOME" | \
    "$PICKER" -p "🔍 Buscar arquivo")

if [ -n "$CHOSEN" ]; then
    xdg-open "$CHOSEN" &
fi
