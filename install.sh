#!/bin/bash

# Cores para deixar bonito
GREEN="\e[32m"
RED="\e[31m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BLUE}=== Bem-vindo ao instalador do meu setup Linux! ===${RESET}"

# Verifica se está rodando como root (yay não permite root)
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}[!] Por favor, não rode este script como root. Rode normalmente e ele pedirá a senha do sudo quando precisar.${RESET}"
  exit 1
fi

# 1. Garantir que temos o yay (AUR helper)
if ! command -v yay &> /dev/null; then
  echo -e "${BLUE}[*] Instalando dependências básicas e o yay...${RESET}"
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
else
  echo -e "${GREEN}[v] yay já está instalado.${RESET}"
fi

# 2. Instalar todos os pacotes
echo -e "${BLUE}[*] Lendo pacotes_instalados.txt e instalando...${RESET}"
if [ -f "pacotes_instalados.txt" ]; then
    # Usando o yay para instalar pacotes do repositório oficial e do AUR
    yay -S --needed --noconfirm - < pacotes_instalados.txt
else
    echo -e "${RED}[!] Arquivo pacotes_instalados.txt não encontrado!${RESET}"
fi

# 3. Restaurar as configurações (dotfiles)
echo -e "${BLUE}[*] Restaurando as configurações da pasta .config e arquivos da Home...${RESET}"
mkdir -p ~/.config

# Copia tudo que está dentro da pasta config do repositório para o ~/.config do usuário
cp -r ./config/* ~/.config/ 2>/dev/null || true

# Copia arquivos avulsos para a home
cp .zshrc .bashrc .gitconfig ~/ 2>/dev/null || true
echo -e "${GREEN}[v] Configurações copiadas com sucesso!${RESET}"

# 4. Permissões e scripts extras
echo -e "${BLUE}[*] Preparando scripts adicionais...${RESET}"
if [ -d "scripts" ]; then
    chmod +x ./scripts/*.sh
    echo -e "${GREEN}[v] Scripts em ./scripts estão prontos para uso.${RESET}"
    
    # Se você quiser que o script já rode os outros automaticamente, pode descomentar as linhas abaixo:
    # ./scripts/install_zsh_omz.sh
    # ./scripts/install_rofi_plugins.sh
fi

# 6. Ativar serviços (Systemd)
echo -e "${BLUE}[*] Ativando serviços do sistema (Login, Internet, Bluetooth, Docker, etc)...${RESET}"
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable ly
sudo systemctl enable docker
sudo systemctl enable cronie
sudo systemctl enable tlp
sudo systemctl enable ufw
sudo systemctl enable cups

echo -e "${BLUE}[*] Configurando o ZSH como shell padrão...${RESET}"
if command -v zsh &> /dev/null; then
    sudo chsh -s $(which zsh) $USER
fi

echo -e "${GREEN}=== Instalação finalizada com sucesso! ===${RESET}"
echo -e "Recomendo reiniciar o sistema para que todas as alterações (como troca de shell e serviços) façam efeito."
