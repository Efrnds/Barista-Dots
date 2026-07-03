#!/bin/bash

# Menu Rofi categorizado para lançar aplicativos de forma rápida

CATEGORIAS="🎮 Jogos\n💻 Desenvolvimento\n🌐 Internet & Social\n🔧 Utilitários & Sistema"

ESCOLHA_CAT=$(echo -e "$CATEGORIAS" | rofi -dmenu -p "🚀 Categorias" -i -theme-str "window {width: 25%;} listview {lines: 4;}")

case "$ESCOLHA_CAT" in
    "🎮 Jogos")
        APPS="Steam\nLutris\nPrism Launcher (Minecraft)\nHeroic Games Launcher"
        ESCOLHA_APP=$(echo -e "$APPS" | rofi -dmenu -p "🎮 Jogos" -i -theme-str "window {width: 25%;} listview {lines: 4;}")
        case "$ESCOLHA_APP" in
            "Steam") steam & ;;
            "Lutris") lutris & ;;
            "Prism Launcher (Minecraft)") prismlauncher & ;;
            "Heroic Games Launcher") heroic & ;;
        esac
        ;;
    "💻 Desenvolvimento")
        APPS="Cursor (Editor)\nFoot (Terminal)\nNeovim\nGitKraken\nDBeaver"
        ESCOLHA_APP=$(echo -e "$APPS" | rofi -dmenu -p "💻 Dev" -i -theme-str "window {width: 25%;} listview {lines: 5;}")
        case "$ESCOLHA_APP" in
            "Cursor (Editor)") cursor & ;;
            "Foot (Terminal)") foot & ;;
            "Neovim") foot -e nvim & ;;
            "GitKraken") gitkraken & ;;
            "DBeaver") dbeaver & ;;
        esac
        ;;
    "🌐 Internet & Social")
        APPS="Zen Browser\nGoogle Chrome\nSpotify\nDiscord\nFirefox"
        ESCOLHA_APP=$(echo -e "$APPS" | rofi -dmenu -p "🌐 Web/Social" -i -theme-str "window {width: 25%;} listview {lines: 5;}")
        case "$ESCOLHA_APP" in
            "Zen Browser") zen-browser & ;;
            "Google Chrome") google-chrome-stable & ;;
            "Spotify") spotify & ;;
            "Discord") discord & ;;
            "Firefox") firefox & ;;
        esac
        ;;
    "🔧 Utilitários & Sistema")
        APPS="Editar Configs (Rofi)\nMixer de Áudio\nFaxina do Sistema\nMonitor de Recursos (Btop)"
        ESCOLHA_APP=$(echo -e "$APPS" | rofi -dmenu -p "🔧 Sistema" -i -theme-str "window {width: 25%;} listview {lines: 4;}")
        case "$ESCOLHA_APP" in
            "Editar Configs (Rofi)") ~/.config/hypr/scripts/edit_configs.sh & ;;
            "Mixer de Áudio") ~/.config/hypr/scripts/rofi_volume_mixer.py & ;;
            "Faxina do Sistema") foot -e ~/.config/hypr/scripts/limpar_sistema.sh & ;;
            "Monitor de Recursos (Btop)") foot --title="btop" --app-id="btop" -e btop & ;;
        esac
        ;;
esac
