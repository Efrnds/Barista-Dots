#!/usr/bin/env bash
# Foot default shell: attach to a shared tmux session (or create it).
exec tmux new-session -A -s main
