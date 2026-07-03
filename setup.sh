#!/bin/bash

echo "🚀 Iniciando a instalação do Setup..."
echo "📦 Baixando o repositório..."

# Garante que o git está instalado
if ! command -v git &> /dev/null; then
    sudo pacman -S --noconfirm git
fi

# Clona o repositório para a home do usuário
git clone https://github.com/Efrnds/Barista-Dots.git ~/dotfiles

# Entra na pasta e roda o instalador principal
cd ~/dotfiles
chmod +x install.sh
./install.sh
