#!/usr/bin/env bash
# Carrega ~/.config/dotfiles/user.conf com defaults seguros.
set -euo pipefail

_user_conf="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/user.conf"
if [[ -f "$_user_conf" ]]; then
  # shellcheck source=/dev/null
  source "$_user_conf"
fi

: "${TERMINAL_CMD:=/usr/bin/foot}"
: "${TERMINAL_CLASS:=foot}"
: "${BROWSER_CMD:=zen-browser}"
: "${BROWSER_CLASS:=zen}"
: "${FILE_MANAGER_CMD:=yazi}"
: "${CURSOR_APP:=$HOME/Applications/cursor.AppImage}"
: "${EDITOR_CMD:=$CURSOR_APP --no-sandbox}"
