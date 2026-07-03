#!/bin/bash

# Script para instalar o tema do GRUB do Catppuccin Macchiato
echo "=== Instalando Tema do GRUB Catppuccin Macchiato ==="

THEME_DIR="/boot/grub/themes"
TEMP_DIR="/tmp/catppuccin-grub"

# Cria o diretório de temas se não existir
sudo mkdir -p "$THEME_DIR"

# Limpa instalações temporárias anteriores
sudo rm -rf "$TEMP_DIR"

# Clona o repositório
echo "Clonando repositório de temas..."
git clone https://github.com/catppuccin/grub.git "$TEMP_DIR"

# Copia o tema do Macchiato
echo "Copiando arquivos do tema..."
sudo cp -r "$TEMP_DIR/src/catppuccin-macchiato-grub-theme" "$THEME_DIR/"

# Modifica o arquivo /etc/default/grub para apontar para o novo tema
echo "Configurando o arquivo /etc/default/grub..."
# Remove qualquer linha de tema anterior
sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub
# Adiciona o novo tema
echo 'GRUB_THEME="/boot/grub/themes/catppuccin-macchiato-grub-theme/theme.txt"' | sudo tee -a /etc/default/grub

# Atualiza a configuração do GRUB
echo "Atualizando configurações do GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "Tema do GRUB instalado com sucesso! 🚀 Na próxima inicialização você verá o novo visual."
