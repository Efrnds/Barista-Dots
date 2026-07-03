#!/bin/bash

# Alternador interativo de Saída/Entrada de Áudio via Rofi + pactl

CATEGORIAS="🔊 Alterar Dispositivo de Saída (Alto-falante/Fone)\n🎤 Alterar Dispositivo de Entrada (Microfone)"

ESCOLHA_CAT=$(echo -e "$CATEGORIAS" | rofi -dmenu -p "🎛️ Dispositivos de Áudio" -i -theme-str "window {width: 32%;} listview {lines: 2;}")

if [ -z "$ESCOLHA_CAT" ]; then
    exit 0
fi

if [[ "$ESCOLHA_CAT" == *"Saída"* ]]; then
    # Lista saídas de som (Sinks)
    SINKS=$(pactl list sinks | grep -E "Name:|Description:" | paste - - | sed -E 's/Name: //g' | sed -E 's/\s*Description: /➔ /')
    
    CHOSEN=$(echo -e "$SINKS" | rofi -dmenu -p "🔊 Selecione a Saída" -i -theme-str "window {width: 40%;} listview {lines: 6;}")
    
    if [ -n "$CHOSEN" ]; then
        SINK_NAME=$(echo "$CHOSEN" | cut -d'➔' -f1 | sed 's/ //g')
        SINK_DESC=$(echo "$CHOSEN" | cut -d'➔' -f2)
        pactl set-default-sink "$SINK_NAME"
        notify-send -a "Áudio" -t 2000 "Saída de Som Alterada" "Ativo: $SINK_DESC"
    fi
else
    # Lista entradas de som (Sources/Microphones)
    SOURCES=$(pactl list sources | grep -E "Name:|Description:" | paste - - | sed -E 's/Name: //g' | sed -E 's/\s*Description: /➔ /')
    
    CHOSEN=$(echo -e "$SOURCES" | rofi -dmenu -p "🎤 Selecione o Microfone" -i -theme-str "window {width: 40%;} listview {lines: 6;}")
    
    if [ -n "$CHOSEN" ]; then
        SOURCE_NAME=$(echo "$CHOSEN" | cut -d'➔' -f1 | sed 's/ //g')
        SOURCE_DESC=$(echo "$CHOSEN" | cut -d'➔' -f2)
        pactl set-default-source "$SOURCE_NAME"
        notify-send -a "Áudio" -t 2000 "Microfone Alterado" "Ativo: $SOURCE_DESC"
    fi
fi
