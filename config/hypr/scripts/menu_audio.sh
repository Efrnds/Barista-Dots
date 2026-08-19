#!/bin/bash

# Alternador interativo de Saída/Entrada de Áudio via EWW picker + pactl

PICKER="$HOME/.config/hypr/scripts/picker.sh"

CATEGORIAS="🔊 Alterar Dispositivo de Saída (Alto-falante/Fone)
🎤 Alterar Dispositivo de Entrada (Microfone)"

ESCOLHA_CAT=$(echo -e "$CATEGORIAS" | "$PICKER" -p "🎛️ Dispositivos de Áudio")

if [ -z "$ESCOLHA_CAT" ]; then
    exit 0
fi

if [[ "$ESCOLHA_CAT" == *"Saída"* ]]; then
    SINKS=$(pactl list sinks | grep -E "Name:|Description:" | paste - - | sed -E 's/Name: //g' | sed -E 's/\s*Description: /➔ /')

    CHOSEN=$(echo -e "$SINKS" | "$PICKER" -p "🔊 Selecione a Saída")

    if [ -n "$CHOSEN" ]; then
        SINK_NAME=$(echo "$CHOSEN" | cut -d'➔' -f1 | sed 's/ //g')
        SINK_DESC=$(echo "$CHOSEN" | cut -d'➔' -f2)
        pactl set-default-sink "$SINK_NAME"
        notify-send -a "Áudio" -t 2000 "Saída de Som Alterada" "Ativo: $SINK_DESC"
    fi
else
    SOURCES=$(pactl list sources | grep -E "Name:|Description:" | paste - - | sed -E 's/Name: //g' | sed -E 's/\s*Description: /➔ /')

    CHOSEN=$(echo -e "$SOURCES" | "$PICKER" -p "🎤 Selecione o Microfone")

    if [ -n "$CHOSEN" ]; then
        SOURCE_NAME=$(echo "$CHOSEN" | cut -d'➔' -f1 | sed 's/ //g')
        SOURCE_DESC=$(echo "$CHOSEN" | cut -d'➔' -f2)
        pactl set-default-source "$SOURCE_NAME"
        notify-send -a "Áudio" -t 2000 "Microfone Alterado" "Ativo: $SOURCE_DESC"
    fi
fi
