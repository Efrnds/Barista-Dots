#!/bin/bash

# Script para instalar os plugins do Rofi (Calculadora e Emojis)
echo "=== Instalando Plugins do Rofi ==="

# Instala os pacotes necessários do repositório oficial do Arch Linux
sudo pacman -S --noconfirm rofi-calc rofi-emoji

echo "Plugins do Rofi instalados com sucesso! 🚀"
echo "O Hyprland já foi atualizado com as seguintes teclas de atalho:"
echo "  - SUPER + SHIFT + C  ->  Calculadora rápida"
echo "  - SUPER + .          ->  Seletor de Emojis"
