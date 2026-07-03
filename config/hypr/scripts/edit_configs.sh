#!/bin/bash

# Script para abrir arquivos de configuração rapidamente via Rofi

declare -A CONFIGS
CONFIGS=(
    ["󱂬 Hyprland (Conf)"]="$HOME/.config/hypr/hyprland.conf"
    ["󱂬 Hyprland (Cores)"]="$HOME/.config/hypr/theme_colors.conf"
    [" Waybar (Config)"]="$HOME/.config/waybar/config.jsonc"
    [" Waybar (Estilo)"]="$HOME/.config/waybar/style.css"
    [" Rofi (Config)"]="$HOME/.config/rofi/config.rasi"
    ["󰞷 Foot Terminal"]="$HOME/.config/foot/foot.ini"
    [" Neovim (init.lua)"]="$HOME/.config/nvim/init.lua"
    ["📁 Yazi (Tema)"]="$HOME/.config/yazi/theme.toml"
    ["📁 Yazi (Geral)"]="$HOME/.config/yazi/yazi.toml"
    ["󰌾 Ly (Login DM)"]="/etc/ly/config.ini"
    [" wlogout (Layout)"]="$HOME/.config/wlogout/layout"
    [" wlogout (Estilo)"]="$HOME/.config/wlogout/style.css"
)

# Gera a lista de chaves para o Rofi
CHOSEN=$(printf "%s\n" "${!CONFIGS[@]}" | sort | rofi -dmenu -p "📝 Editar Configs" -i -theme-str 'window {width: 30%;} listview {lines: 10;}')

if [ -n "$CHOSEN" ]; then
    FILE="${CONFIGS[$CHOSEN]}"
    
    # Se for o arquivo do Ly, abre com sudo no nvim, senão abre no Cursor
    if [ "$FILE" = "/etc/ly/config.ini" ]; then
        foot -e sudo nvim "$FILE"
    else
        # Abre no Cursor
        /home/eduardo/Applications/cursor.AppImage "$FILE" &
    fi
fi
