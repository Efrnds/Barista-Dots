#!/bin/bash

# Script de conexão de Bluetooth usando Rofi e bluetoothctl

BT_STATUS=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$BT_STATUS" = "yes" ]; then
    TOGGLE="󰂲  Desligar Bluetooth"
else
    TOGGLE="󰂯  Ligar Bluetooth"
fi

# Lista dispositivos pareados e conhecidos
DEVICES=$(bluetoothctl devices | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')
LIST=$(echo -e "$TOGGLE\n$DEVICES" | sed '/^$/d')

# Abre o Rofi para seleção do dispositivo
CHOSEN=$(echo -e "$LIST" | rofi -dmenu -i -p "󰂯  Bluetooth" -theme-str 'window {width: 25%;} listview {lines: 10;}')

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if [ "$CHOSEN" = "󰂯  Ligar Bluetooth" ]; then
    bluetoothctl power on
    notify-send "Bluetooth" "Ativado 🚀"
elif [ "$CHOSEN" = "󰂲  Desligar Bluetooth" ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Desativado 🔌"
else
    # Pega o endereço MAC do dispositivo escolhido
    MAC=$(bluetoothctl devices | grep "$CHOSEN" | awk '{print $2}')
    
    if [ -n "$MAC" ]; then
        notify-send "Bluetooth" "Conectando a $CHOSEN..."
        CONNECTION_RESULT=$(bluetoothctl connect "$MAC" 2>&1)
        if echo "$CONNECTION_RESULT" | grep -q "Connection successful"; then
            notify-send "Bluetooth" "Conectado a $CHOSEN 🚀"
        else
            # Se já estiver conectado, desconecta
            DISCONNECT_RESULT=$(bluetoothctl disconnect "$MAC" 2>&1)
            if echo "$DISCONNECT_RESULT" | grep -q "Successful"; then
                notify-send "Bluetooth" "Desconectado de $CHOSEN 🔌"
            else
                notify-send -u critical "Bluetooth" "Falha: $CONNECTION_RESULT ❌"
            fi
        fi
    fi
fi
