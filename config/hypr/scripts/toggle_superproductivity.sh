#!/bin/bash

# Detecta qual executável está disponível no sistema
if command -v superproductivity >/dev/null 2>&1; then
    CMD="superproductivity"
elif command -v super-productivity >/dev/null 2>&1; then
    CMD="super-productivity"
else
    CMD="superproductivity" # fallback padrão
fi

# Verifica se o processo já está rodando
if ! pgrep -xi "superproductiv" > /dev/null && ! pgrep -xi "super-productiv" > /dev/null; then
    $CMD &
    # Aguarda o processo iniciar antes de alternar o workspace especial
    sleep 0.5
fi

# Alterna para a área de trabalho especial (scratchpad) do superproductivity
hyprctl dispatch togglespecialworkspace superproductivity
