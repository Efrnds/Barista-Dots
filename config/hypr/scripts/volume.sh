#!/bin/bash

# Altera o volume
case $1 in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

# Pega o volume atual e status de mute
VOL_RAW=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
VOL=$(echo "$VOL_RAW" | awk '{print int($2 * 100)}')
MUTED=$(echo "$VOL_RAW" | grep -o "\[MUTED\]")

if [ -n "$MUTED" ]; then
    notify-send -u low -h string:x-canonical-private-synchronous:volume -t 1000 -i audio-volume-muted "Volume" "Mutado"
else
    # Limita o volume em 100% na barra visual, mesmo se passar de 100%
    VISUAL_VOL=$VOL
    if [ $VISUAL_VOL -gt 100 ]; then
        VISUAL_VOL=100
    fi
    
    BAR=""
    NUM_CHARS=$((VISUAL_VOL / 10))
    for i in {1..10}; do
        if [ $i -le $NUM_CHARS ]; then
            BAR="${BAR}█"
        else
            BAR="${BAR}░"
        fi
    done
    notify-send -u low -h string:x-canonical-private-synchronous:volume -t 1000 -i audio-volume-high "Volume: ${VOL}%" "$BAR"
fi
