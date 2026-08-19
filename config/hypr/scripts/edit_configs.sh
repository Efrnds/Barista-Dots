#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/dotfiles-env.sh"

PICKER="$HOME/.config/hypr/scripts/picker.sh"

declare -A CONFIGS
CONFIGS=(
  ["Hyprland (Lua)"]="$HOME/.config/hypr/hyprland.lua"
  ["Hyprland (Cores)"]="$HOME/.config/hypr/theme_colors.conf"
  ["Foot Terminal"]="$HOME/.config/foot/foot.ini"
  ["Neovim"]="$HOME/.config/nvim/init.lua"
  ["Yazi (Tema)"]="$HOME/.config/yazi/theme.toml"
  ["Yazi (Geral)"]="$HOME/.config/yazi/yazi.toml"
  ["DMS Settings"]="$HOME/.config/DankMaterialShell/settings.json"
  ["tmux"]="$HOME/.config/tmux/tmux.conf"
  ["Dotfiles user.conf"]="$HOME/.config/dotfiles/user.conf"
  ["Ly (Login)"]="/etc/ly/config.ini"
)

CHOSEN=$(printf "%s\n" "${!CONFIGS[@]}" | sort | "$PICKER" -p "Editar Configs")

if [[ -n "${CHOSEN:-}" ]]; then
  FILE="${CONFIGS[$CHOSEN]}"
  if [[ "$FILE" == "/etc/ly/config.ini" ]]; then
    foot -e sudo nvim "$FILE"
  elif [[ -x "$CURSOR_APP" ]]; then
    "$CURSOR_APP" "$FILE" &
  else
    foot -e "${EDITOR:-nvim}" "$FILE"
  fi
fi
