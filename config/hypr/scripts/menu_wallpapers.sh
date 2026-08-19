#!/bin/bash

# Gerenciador de wallpapers via DMS (sem iNiR/Eww)

PICKER="$HOME/.config/hypr/scripts/picker.sh"

options="🎨 Color Picker (Tema)
🎲 Próximo Wallpaper (DMS)
🖼️ Browser de Wallpapers (DankDash)
📁 Escolher arquivo local
🔮 Synthwave (Wallhaven)
🌌 Cyberpunk
👾 Pixel Art
🏔️ Paisagem (Scenery)
🌌 Espaço / Estrelas (Space)
🎨 Vetorial (Vector)
☕ Lofi / Cozy
🧊 Nord / Clean"

choice=$(echo -e "$options" | "$PICKER" -p "🖼️ Papel de Parede")

if [ -z "$choice" ]; then
  exit 0
fi

case "$choice" in
  "🎨 Color Picker (Tema)")
    dms ipc call color-picker toggle >/dev/null 2>&1 || true
    ;;
  "🎲 Próximo Wallpaper (DMS)")
    dms ipc call wallpaper next >/dev/null 2>&1 || true
    ;;
  "🖼️ Browser de Wallpapers (DankDash)")
    dms ipc call dankdash wallpaper >/dev/null 2>&1 || true
    ;;
  "📁 Escolher arquivo local")
    dms ipc call file browse wallpaper >/dev/null 2>&1 || true
    ;;
  "🔮 Synthwave") ~/.config/hypr/mudar_fundo.sh synthwave ;;
  "🌌 Cyberpunk") ~/.config/hypr/mudar_fundo.sh cyberpunk ;;
  "👾 Pixel Art") ~/.config/hypr/mudar_fundo.sh pixelart ;;
  "🏔️ Paisagem (Scenery)") ~/.config/hypr/mudar_fundo.sh scenery ;;
  "🌌 Espaço / Estrelas (Space)") ~/.config/hypr/mudar_fundo.sh space ;;
  "🎨 Vetorial (Vector)") ~/.config/hypr/mudar_fundo.sh vector ;;
  "☕ Lofi / Cozy") ~/.config/hypr/mudar_fundo.sh lofi ;;
  "🧊 Nord / Clean") ~/.config/hypr/mudar_fundo.sh nord ;;
  *) ;;
esac
