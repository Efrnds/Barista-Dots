#!/usr/bin/env bash
export ALACRITTY_TMUX_SESSION=dev
exec "$(dirname "$0")/alacritty-tmux.sh" dev
