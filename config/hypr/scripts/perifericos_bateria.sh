#!/bin/bash

# Script para monitorar a bateria de fones, mouses e teclados sem fio (Bluetooth/USB)

# Evita spam de notificações guardando o estado dos dispositivos
NOTIFICADOS=""

while true; do
    # Busca por dispositivos de teclado, mouse ou fone no UPower
    DEVICES=$(upower -e | grep -E "keyboard|mouse|headset|gaming_input")

    for DEV in $DEVICES; do
        # Obtém o nome amigável do dispositivo
        MODEL=$(upower -i "$DEV" | grep "model:" | cut -d':' -f2 | sed 's/^ //')
        if [ -z "$MODEL" ]; then
            MODEL=$(basename "$DEV" | sed 's/_/ /g')
        fi

        # Obtém a porcentagem de bateria
        PERCENT=$(upower -i "$DEV" | grep "percentage:" | awk '{print $2}' | tr -d '%')

        if [ -n "$PERCENT" ]; then
            # Se a bateria estiver abaixo de 12%
            if [ "$PERCENT" -le 12 ]; then
                # Verifica se já notificamos sobre esse dispositivo nesta sessão
                if [[ ! "$NOTIFICADOS" =~ "$MODEL" ]]; then
                    notify-send -u critical -a "Dispositivo Sem Fio" "🔋 Bateria Baixa!" "O dispositivo '$MODEL' está com apenas ${PERCENT}% de carga."
                    NOTIFICADOS="$NOTIFICADOS|$MODEL"
                fi
            else
                # Se carregou, remove da lista de notificados para permitir futuros alertas
                NOTIFICADOS=$(echo "$NOTIFICADOS" | sed "s/|$MODEL//")
            fi
        fi
    done

    # Dorme por 5 minutos antes da próxima verificação
    sleep 300
done
