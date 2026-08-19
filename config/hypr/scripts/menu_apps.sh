#!/bin/bash

# Menu categorizado para lançar aplicativos via EWW picker

PICKER="$HOME/.config/hypr/scripts/picker.sh"

CATEGORIAS="🎮 Jogos
💻 Desenvolvimento
🌐 Internet & Social
🔧 Utilitários & Sistema"

ESCOLHA_CAT=$(echo -e "$CATEGORIAS" | "$PICKER" -p "🚀 Categorias")

case "$ESCOLHA_CAT" in
    "🎮 Jogos")
        APPS="Steam
Lutris
Prism Launcher (Minecraft)
Heroic Games Launcher"
        ESCOLHA_APP=$(echo -e "$APPS" | "$PICKER" -p "🎮 Jogos")
        case "$ESCOLHA_APP" in
            "Steam") steam & ;;
            "Lutris") lutris & ;;
            "Prism Launcher (Minecraft)") prismlauncher & ;;
            "Heroic Games Launcher") heroic & ;;
        esac
        ;;
    "💻 Desenvolvimento")
        APPS="Cursor (Editor)
Foot (Terminal)
Neovim
GitKraken
DBeaver"
        ESCOLHA_APP=$(echo -e "$APPS" | "$PICKER" -p "💻 Dev")
        case "$ESCOLHA_APP" in
            "Cursor (Editor)") cursor & ;;
            "Foot (Terminal)") foot & ;;
            "Neovim") foot -e nvim & ;;
            "GitKraken") gitkraken & ;;
            "DBeaver") dbeaver & ;;
        esac
        ;;
    "🌐 Internet & Social")
        APPS="Zen Browser
Google Chrome
Spotify
Discord
Firefox"
        ESCOLHA_APP=$(echo -e "$APPS" | "$PICKER" -p "🌐 Web/Social")
        case "$ESCOLHA_APP" in
            "Zen Browser") zen-browser & ;;
            "Google Chrome") google-chrome-stable & ;;
            "Spotify") spotify & ;;
            "Discord") discord & ;;
            "Firefox") firefox & ;;
        esac
        ;;
    "🔧 Utilitários & Sistema")
        APPS="Editar Configs
Mixer de Áudio
Faxina do Sistema
Monitor de Recursos (Btop)"
        ESCOLHA_APP=$(echo -e "$APPS" | "$PICKER" -p "🔧 Sistema")
        case "$ESCOLHA_APP" in
            "Editar Configs") ~/.config/hypr/scripts/edit_configs.sh & ;;
            "Mixer de Áudio") ~/.config/hypr/scripts/menu_volume_mixer.py & ;;
            "Faxina do Sistema") foot -e ~/.config/hypr/scripts/limpar_sistema.sh & ;;
            "Monitor de Recursos (Btop)") foot --title="btop" --app-id="btop" -e btop & ;;
        esac
        ;;
esac
