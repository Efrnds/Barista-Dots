#!/bin/bash

# Gerenciador de conexões SSH via Rofi (lê de ~/.ssh/config)

SSH_CONFIG="$HOME/.ssh/config"

if [ ! -f "$SSH_CONFIG" ]; then
    notify-send "SSH" "Arquivo ~/.ssh/config não encontrado."
    exit 0
fi

# Extrai os hosts configurados (ignora curingas)
HOSTS=$(grep -E -i "^Host\s+" "$SSH_CONFIG" | awk '{print $2}' | grep -v -E "\*")

if [ -z "$HOSTS" ]; then
    notify-send "SSH" "Nenhum Host SSH configurado em ~/.ssh/config."
    exit 0
fi

# Abre o Rofi
CHOSEN=$(echo -e "$HOSTS" | rofi -dmenu -p "🔑 Conexões SSH" -i -theme-str "window {width: 25%;} listview {lines: 5;}")

if [ -n "$CHOSEN" ]; then
    # Abre uma nova janela do Foot rodando a conexão SSH
    foot --title="SSH: $CHOSEN" -e ssh "$CHOSEN" &
fi
