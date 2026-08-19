#!/bin/bash

# Abre arquivos de configuração via picker

PICKER="$HOME/.config/hypr/scripts/picker.sh"

declare -A CONFIGS
CONFIGS=(
  ["󱂬 Hyprland (Conf)"]="$HOME/.config/hypr/hyprland.conf"
  ["󱂬 Hyprland (Cores)"]="$HOME/.config/hypr/theme_colors.conf"
  ["󰞷 Foot Terminal"]="$HOME/.config/foot/foot.ini"
  [" Neovim (init.lua)"]="$HOME/.config/nvim/init.lua"
  ["📁 Yazi (Tema)"]="$HOME/.config/yazi/theme.toml"
  ["📁 Yazi (Geral)"]="$HOME/.config/yazi/yazi.toml"
  ["󰌾 Ly (Login DM)"]="/etc/ly/config.ini"
)

CHOSEN=$(printf "%s\n" "${!CONFIGS[@]}" | sort | "$PICKER" -p "📝 Editar Configs")

if [ -n "$CHOSEN" ]; then
  FILE="${CONFIGS[$CHOSEN]}"

  # Ly precisa de sudo pra editar
  if [ "$FILE" = "/etc/ly/config.ini" ]; then
    foot -e sudo nvim "$FILE"
  else
    "${HOME}/Applications/cursor.AppImage" "$FILE" &
  fi
fi
