#!/bin/bash

# Verifica se o zsh está instalado
if ! command -v zsh &> /dev/null; then
    echo "Zsh não encontrado. Por favor, aguarde a finalização da instalação pelo pacman."
    exit 1
fi

# Instala o Oh My Zsh se não existir
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Instalando Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh já está instalado."
fi

# Define o tema do Oh My Zsh para um visual limpo que combina com o seu tema
# O tema 'steeef' ou 'clean' ou 'dst' são excelentes opções minimalistas.
# Vamos usar o 'steeef' que mostra apenas o que é necessário de forma muito limpa.
if [ -f "$HOME/.zshrc" ]; then
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="steeef"/g' "$HOME/.zshrc"
    
    # Adiciona alias úteis que você já usava no bashrc
    if ! grep -q "alias cursor=" "$HOME/.zshrc"; then
        echo -e "\n# Aliases do usuário" >> "$HOME/.zshrc"
        echo "alias cursor='${HOME}/Applications/cursor.AppImage'" >> "$HOME/.zshrc"
        echo "alias ls='ls --color=auto'" >> "$HOME/.zshrc"
        echo "alias grep='grep --color=auto'" >> "$HOME/.zshrc"
    fi
fi

# Altera o shell padrão para o zsh
if [ "$SHELL" != "/usr/bin/zsh" ] && [ "$SHELL" != "/bin/zsh" ]; then
    echo "Alterando o shell padrão para Zsh..."
    chsh -s $(which zsh)
fi

echo "Oh My Zsh configurado com sucesso! 🚀 Abra um novo terminal para ver a mudança."
