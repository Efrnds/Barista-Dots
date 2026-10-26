#!/usr/bin/env bash
# Compat: Foot removido — redireciona para Alacritty+tmux
exec "$(dirname "$0")/alacritty-tmux.sh" "$@"
