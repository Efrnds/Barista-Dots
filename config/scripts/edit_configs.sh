#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/dotfiles-env.sh"

PICKER="$HOME/.config/scripts/picker.sh"

declare -A CONFIGS
CONFIGS=(
  ["Niri"]="$HOME/.config/niri/config.kdl"
  ["Alacritty"]="$HOME/.config/alacritty/alacritty.toml"
  ["Neovim"]="$HOME/.config/nvim/init.lua"
  ["DMS Settings"]="$HOME/.config/DankMaterialShell/settings.json"
  ["tmux"]="$HOME/.config/tmux/tmux.conf"
  ["Dotfiles user.conf"]="$HOME/.config/dotfiles/user.conf"
  ["Ly (Login)"]="/etc/ly/config.ini"
)

CHOSEN=$(printf "%s\n" "${!CONFIGS[@]}" | sort | "$PICKER" -p "Editar Configs")

if [[ -n "${CHOSEN:-}" ]]; then
  FILE="${CONFIGS[$CHOSEN]}"
  if [[ "$FILE" == "/etc/ly/config.ini" ]]; then
    alacritty -e sudo nvim "$FILE"
  elif [[ -x "$CURSOR_APP" ]]; then
    "$CURSOR_APP" "$FILE" &
  else
    alacritty -e "${EDITOR:-nvim}" "$FILE"
  fi
fi
