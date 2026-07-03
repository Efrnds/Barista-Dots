#!/bin/bash

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Clona zsh-autosuggestions se não existir
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "Clonando zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Clona zsh-syntax-highlighting se não existir
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "Clonando zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Atualiza a lista de plugins no ~/.zshrc
if [ -f "$HOME/.zshrc" ]; then
    if grep -q "plugins=(git)" "$HOME/.zshrc"; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$HOME/.zshrc"
        echo "Plugins adicionados ao seu ~/.zshrc! 🚀"
    else
        echo "Seu ~/.zshrc tem uma lista de plugins modificada. Por favor, adicione 'zsh-autosuggestions' e 'zsh-syntax-highlighting' manualmente em plugins=(...)."
    fi
fi
