#!/usr/bin/env bash
set -euo pipefail

SPECIAL="superproductivity"

# Detecta qual executável está disponível no sistema
if command -v superproductivity >/dev/null 2>&1; then
    CMD="superproductivity"
elif command -v super-productivity >/dev/null 2>&1; then
    CMD="super-productivity"
else
    CMD="superproductivity"
fi

if ! pgrep -xi "superproductiv" > /dev/null && ! pgrep -xi "super-productiv" > /dev/null; then
    "$CMD" &
    sleep 0.5
fi

hyprctl dispatch 'hl.dsp.workspace.toggle_special("superproductivity")'
