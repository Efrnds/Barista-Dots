#!/usr/bin/env bash
# Abre terminal padrão (Alacritty).
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/dotfiles-env.sh"

cmd="${TERMINAL_CMD:-alacritty}"
# resolve no PATH / local-bin
if [[ "$cmd" == */* ]]; then
  exec $cmd
fi
if command -v "$cmd" >/dev/null 2>&1; then
  exec "$cmd"
fi
# fallbacks
if [[ -x "$HOME/.local/bin/alacritty-tmux.sh" ]]; then
  exec alacritty -e "$HOME/.local/bin/alacritty-tmux.sh"
fi
exec alacritty
