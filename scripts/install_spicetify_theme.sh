#!/bin/bash

# Script para instalar o Spicetify e aplicar o tema Catppuccin Macchiato Lavender no Spotify

echo "=== Iniciando Configuração do Spicetify ==="

# 1. Instala o Spicetify via AUR (yay) se não estiver instalado
if ! command -v spicetify &> /dev/null; then
    echo "Instalando spicetify-cli via AUR..."
    yay -S --noconfirm spicetify-cli
fi

# 2. Concede permissões para o Spotify (necessário para o Spicetify aplicar os temas)
echo "Ajustando as permissões da pasta do Spotify..."
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R

# 3. Executa o primeiro backup e configuração básica do Spicetify
echo "Gerando backup inicial do Spotify..."
spicetify backup apply

# 4. Baixa os temas oficiais do Catppuccin para o Spicetify
echo "Clonando o repositório de temas do Catppuccin..."
mkdir -p ~/.config/spicetify/Themes
rm -rf ~/.config/spicetify/Themes/catppuccin
rm -rf ~/.config/spicetify/Themes/catppuccin_repo

# Clona em uma pasta temporária
git clone https://github.com/catppuccin/spicetify.git ~/.config/spicetify/Themes/catppuccin_repo

# Move a pasta real do tema para o local correto
cp -r ~/.config/spicetify/Themes/catppuccin_repo/catppuccin ~/.config/spicetify/Themes/catppuccin

# Limpa a pasta temporária
rm -rf ~/.config/spicetify/Themes/catppuccin_repo

# 5. Aplica a flavor Macchiato com detalhes roxo/lavanda
echo "Configurando o tema no Spicetify..."
spicetify config current_theme catppuccin color_scheme macchiato
spicetify apply

echo "=== Spicetify Configurado! 🚀 ==="
echo "Seu Spotify agora está no tema Catppuccin Macchiato Lavender!"
