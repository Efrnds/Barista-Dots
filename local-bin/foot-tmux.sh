#!/usr/bin/env bash
# Foot default shell: attach/create tmux session (default: main).
SESSION="${FOOT_TMUX_SESSION:-${1:-main}}"
export TMUX=
exec tmux new-session -A -s "$SESSION"
