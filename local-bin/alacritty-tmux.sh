#!/usr/bin/env bash
# Cada janela Alacritty ganha a PRÓPRIA sessão tmux (panes/windows locais).
# Para colar numa sessão compartilhada: ALACRITTY_TMUX_SESSION=main alacritty
set -euo pipefail

export TMUX=

if [[ -n "${ALACRITTY_TMUX_SESSION:-}" ]]; then
  exec tmux new-session -A -s "$ALACRITTY_TMUX_SESSION"
fi

# Sessão única por processo — várias Alacritty ao mesmo tempo
exec tmux new-session -s "a-$$-$(date +%s%N | tail -c 5)"
