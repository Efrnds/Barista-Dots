#!/bin/bash

# Script de controle de mídia e brilho usando Rofi

# Pega o volume atual
VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOL=$(echo "$VOL_RAW" | awk '{print int($2 * 100)}')
MUTED=$(echo "$VOL_RAW" | grep -o "\[MUTED\]")

if [ -n "$MUTED" ]; then
    VOL_TEXT="Mutado"
else
    VOL_TEXT="${VOL}%"
fi

# Pega o brilho atual
CURR=$(brightnessctl g)
MAX=$(brightnessctl m)
BRIGHT=$(( CURR * 100 / MAX ))

# Opções do menu
OPTIONS="🔊 Aumentar Volume (+5%)
🔉 Diminuir Volume (-5%)
🔇 Alternar Mudo
 Aumentar Brilho (+5%)
 Diminuir Brilho (-5%)"

# Exibe o menu no Rofi
CHOSEN=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "🔊 Mídia (Vol: $VOL_TEXT | Brilho: $BRIGHT%)" -theme-str 'window {width: 25%;} listview {lines: 5;}')

if [ -z "$CHOSEN" ]; then
    exit 0
fi

case "$CHOSEN" in
    *"Aumentar Volume"*)
        ~/.config/hypr/scripts/volume.sh up
        # Reabre o script para mostrar o valor atualizado em tempo real!
        exec "$0"
        ;;
    *"Diminuir Volume"*)
        ~/.config/hypr/scripts/volume.sh down
        exec "$0"
        ;;
    *"Alternar Mudo"*)
        ~/.config/hypr/scripts/volume.sh mute
        exec "$0"
        ;;
    *"Aumentar Brilho"*)
        ~/.config/hypr/scripts/brightness.sh up
        exec "$0"
        ;;
    *"Diminuir Brilho"*)
        ~/.config/hypr/scripts/brightness.sh down
        exec "$0"
        ;;
esac
