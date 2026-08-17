#!/bin/bash

# Script para selecionar temas de wallpaper ou gerenciar favoritos via Rofi
# Integrado com o mudar_fundo.sh

# Seletor do Rofi
rofi_cmd() {
    rofi -dmenu \
         -p "🖼️ Papel de Parede" \
         -mesg "Escolha um tema de busca ou gerencie seus favoritos" \
         -i \
         -theme-str 'window {width: 32%;} listview {lines: 10;}'
}

# Opções do menu
options="🎨 Color Picker (Criar tema a partir de uma cor)
🔓 Destravar Tema (Sincronizar com o Wallpaper)
🎲 Aleatório (Com cores do tema)
🎲 Aleatório (Sem restrição de cor)
❤️ Curtir Wallpaper Atual (Salvar Local)
📁 Meus Favoritos Locais (Aleatório)
🎬 Live Wallpaper Aleatório (Vídeo da Web)
🌌 Cyberpunk
👾 Pixel Art
🏔️ Paisagem (Scenery)
🌌 Espaço / Estrelas (Space)
🎨 Vetorial (Vector)
☕ Lofi / Cozy
🧊 Nord / Clean
🔮 Synthwave"

choice=$(echo -e "$options" | rofi_cmd)

# Se cancelar o menu
if [ -z "$choice" ]; then
    exit 0
fi

case "$choice" in
    "🎨 Color Picker (Criar tema a partir de uma cor)")
        ~/dotfiles/scripts/rice_color_picker.sh
        ;;
    "🔓 Destravar Tema (Sincronizar com o Wallpaper)")
        rm -f ~/.config/hypr/theme_locked
        if [ -f ~/.config/hypr/current_wallpaper.jpg ]; then
            ~/dotfiles/scripts/rice_dinamico.sh ~/.config/hypr/current_wallpaper.jpg
        fi
        ;;
    "🎲 Aleatório (Com cores do tema)")
        ~/.config/hypr/mudar_fundo.sh
        ;;
    "🎲 Aleatório (Sem restrição de cor)")
        ~/.config/hypr/mudar_fundo.sh --nocolor
        ;;
    "❤️ Curtir Wallpaper Atual (Salvar Local)")
        ~/.config/hypr/mudar_fundo.sh --like
        ;;
    "📁 Meus Favoritos Locais (Aleatório)")
        ~/.config/hypr/mudar_fundo.sh --local
        ;;
    "🎬 Live Wallpaper Aleatório (Vídeo da Web)")
        ~/.config/hypr/mudar_fundo.sh --live
        ;;
    "🌌 Cyberpunk")
        ~/.config/hypr/mudar_fundo.sh cyberpunk
        ;;
    "👾 Pixel Art")
        ~/.config/hypr/mudar_fundo.sh pixelart
        ;;
    "🏔️ Paisagem (Scenery)")
        ~/.config/hypr/mudar_fundo.sh scenery
        ;;
    "🌌 Espaço / Estrelas (Space)")
        ~/.config/hypr/mudar_fundo.sh space
        ;;
    "🎨 Vetorial (Vector)")
        ~/.config/hypr/mudar_fundo.sh vector
        ;;
    "☕ Lofi / Cozy")
        ~/.config/hypr/mudar_fundo.sh lofi
        ;;
    "🧊 Nord / Clean")
        ~/.config/hypr/mudar_fundo.sh nord
        ;;
    "🔮 Synthwave")
        ~/.config/hypr/mudar_fundo.sh synthwave
        ;;
esac
