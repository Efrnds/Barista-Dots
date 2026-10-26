#!/usr/bin/env bash
# Foot direto (sem tmux). Tmux+extended-keys quebrava Ctrl+V → imagem no agent.
# Se quiser tmux: `tmux` dentro do foot, com ~/.config/tmux/tmux.conf (sem extended-keys).
set -euo pipefail
exec foot "$@"
