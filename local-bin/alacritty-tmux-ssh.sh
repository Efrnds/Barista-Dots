#!/usr/bin/env bash
export ALACRITTY_TMUX_SESSION=ssh
exec "$(dirname "$0")/alacritty-tmux.sh" ssh
