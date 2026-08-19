#!/bin/bash

# Gerenciador de conexões SSH via EWW picker (lê de ~/.ssh/config)

PICKER="$HOME/.config/hypr/scripts/picker.sh"
SSH_CONFIG="$HOME/.ssh/config"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/eww/ssh-menu.log"

log() {
    mkdir -p "$(dirname "$LOG")"
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"
}

if [ ! -f "$SSH_CONFIG" ]; then
    notify-send "SSH" "Arquivo ~/.ssh/config não encontrado."
    exit 0
fi

HOSTS=$(grep -E -i '^Host[[:space:]]+' "$SSH_CONFIG" | awk '{print $2}' | grep -vE '\*')

if [ -z "$HOSTS" ]; then
    notify-send "SSH" "Nenhum Host SSH configurado em ~/.ssh/config."
    exit 0
fi

CHOSEN=$(echo "$HOSTS" | "$PICKER" -p 'Conexoes SSH' | tr -d '\r\n' | xargs)
log "chosen=[$CHOSEN]"

if [ -z "$CHOSEN" ]; then
    log "empty choice, abort"
    exit 0
fi

# foot: -e é ignorado; comando vai direto após as opções
hyprctl dispatch exec "[float] foot --app-id=ssh-${CHOSEN} --title=SSH:${CHOSEN} ssh ${CHOSEN}" &
log "launched foot ssh ${CHOSEN}"
