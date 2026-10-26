#!/usr/bin/env bash
# Atalho opcional: sempre a sessão tmux "main" (compartilhada entre janelas).
export ALACRITTY_TMUX_SESSION=main
exec "$(dirname "$0")/alacritty-tmux.sh"
