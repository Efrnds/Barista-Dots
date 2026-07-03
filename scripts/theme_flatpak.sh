#!/bin/bash

# Script para aplicar o tema GTK do sistema nos pacotes Flatpak
echo "=== Configurando Temas para Flatpaks ==="

# Permite que os Flatpaks acessem os diretórios de temas e ícones do sistema e do usuário
flatpak override --user --filesystem="$HOME/.themes"
flatpak override --user --filesystem="$HOME/.icons"
flatpak override --user --filesystem="/usr/share/themes:ro"
flatpak override --user --filesystem="/usr/share/icons:ro"

# Define as variáveis de ambiente para forçar o tema e ícones nos Flatpaks
flatpak override --user --env=GTK_THEME="catppuccin-macchiato-lavender-standard+default"
flatpak override --user --env=ICON_THEME="Papirus-Dark"

echo "Flatpaks configurados com sucesso! 🚀 Agora os aplicativos Flatpak seguirão o mesmo tema visual."
