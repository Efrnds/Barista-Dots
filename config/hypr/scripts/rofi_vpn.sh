#!/bin/bash

# Gerenciador de VPN interativo via Rofi usando nmcli

# Lista conexões de tipo vpn, wireguard ou tun
VPNS=$(nmcli -t -f NAME,TYPE connection show | grep -E ":vpn|:wireguard|:tun" | cut -d':' -f1)

if [ -z "$VPNS" ]; then
    notify-send "VPN" "Nenhuma conexão VPN ou WireGuard encontrada no NetworkManager."
    exit 0
fi

# Cria opções e mapeia estados
OPCOES=""
declare -A ESTADO_MAP

while read -r NAME; do
    if [ -z "$NAME" ]; then continue; fi
    
    # Checa se está ativa
    IS_ACTIVE=$(nmcli -t -f NAME,ACTIVE connection show | grep "^${NAME}:" | cut -d':' -f2)
    
    if [ "$IS_ACTIVE" = "yes" ]; then
        LABEL="🟢 $NAME (Conectada)"
        ESTADO_MAP["$LABEL"]="up"
    else
        LABEL="⚫ $NAME (Desconectada)"
        ESTADO_MAP["$LABEL"]="down"
    fi
    OPCOES+="$LABEL\n"
done <<< "$VPNS"

# Abre o Rofi
CHOSEN=$(echo -e "$OPCOES" | sed '/^$/d' | rofi -dmenu -p "🌐 VPNs / WireGuard" -i -theme-str "window {width: 30%;} listview {lines: 5;}")

if [ -n "$CHOSEN" ]; then
    ACTION=${ESTADO_MAP["$CHOSEN"]}
    # Limpa a string para pegar o nome da conexão
    VPN_NAME=$(echo "$CHOSEN" | sed -E 's/^(🟢|⚫) //g' | sed 's/ (Conectada)//g' | sed 's/ (Desconectada)//g')
    
    if [ "$ACTION" = "up" ]; then
        notify-send "VPN" "Desconectando de $VPN_NAME..."
        nmcli connection down "$VPN_NAME"
    else
        notify-send "VPN" "Conectando a $VPN_NAME..."
        nmcli connection up "$VPN_NAME"
    fi
fi
