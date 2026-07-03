#!/bin/bash

# Script de conexão de Wi-Fi usando Rofi e nmcli

WIFI_STATUS=$(nmcli -fields WIFI g | sed 1d | xargs)

if [ "$WIFI_STATUS" = "enabled" ]; then
    TOGGLE="󰖪  Desligar Wi-Fi"
else
    TOGGLE="󰖩  Ligar Wi-Fi"
fi

# Lista as redes Wi-Fi ignorando duplicadas e linhas vazias
MAPS=$(nmcli --fields "SECURITY,SSID" device wifi list | sed 1d | grep -v '^\s*$' | awk -F'  +' '{print $2}' | sort -u)
LIST=$(echo -e "$TOGGLE\n$MAPS" | sed '/^$/d')

# Abre o Rofi para seleção de rede
CHOSEN_NETWORK=$(echo -e "$LIST" | rofi -dmenu -i -p "󰖩  Wi-Fi" -theme-str 'window {width: 25%;} listview {lines: 10;}')

if [ -z "$CHOSEN_NETWORK" ]; then
    exit 0
fi

if [ "$CHOSEN_NETWORK" = "󰖩  Ligar Wi-Fi" ]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Ativado 🚀"
elif [ "$CHOSEN_NETWORK" = "󰖪  Desligar Wi-Fi" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Desativado 🔌"
else
    # Verifica a segurança da rede escolhida
    SECURE=$(nmcli -fields "SECURITY,SSID" device wifi list | grep "$CHOSEN_NETWORK" | awk '{print $1}' | head -n 1)

    if [ "$SECURE" = "--" ] || [ -z "$SECURE" ]; then
        # Rede aberta (sem senha)
        nmcli device wifi connect "$CHOSEN_NETWORK"
        notify-send "Wi-Fi" "Conectado a $CHOSEN_NETWORK"
    else
        # Rede protegida, pede senha no Rofi
        WIFI_PASS=$(rofi -dmenu -password -p "🔑 Senha de $CHOSEN_NETWORK:" -theme-str 'window {width: 22%;} listview {lines: 0;}')
        if [ -n "$WIFI_PASS" ]; then
            CONNECTION_RESULT=$(nmcli device wifi connect "$CHOSEN_NETWORK" password "$WIFI_PASS" 2>&1)
            if echo "$CONNECTION_RESULT" | grep -q "successfully"; then
                notify-send "Wi-Fi" "Conectado a $CHOSEN_NETWORK 🚀"
            else
                notify-send -u critical "Wi-Fi" "Falha ao conectar: $CONNECTION_RESULT ❌"
            fi
        fi
    fi
fi
