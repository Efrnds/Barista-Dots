#!/usr/bin/env bash

# Mostra notificação de escaneamento
notify-send -t 1500 "Rede" "Escaneando redes Wi-Fi disponíveis..."

# Verifica status do Wi-Fi
wifi_status=$(nmcli -fields WIFI g | tail -n 1 | tr -d '[:space:]')

if [ "$wifi_status" = "enabled" ]; then
    toggle="󰖪  Desativar Wi-Fi"
else
    toggle="󰖩  Ativar Wi-Fi"
fi

# Pega lista de redes formatada com ícones de segurança
wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | tail -n +2 | \
awk -F'  +' '{
    security = $1;
    ssid = $2;
    if (ssid != "" && ssid != "--") {
        icon = (security != "" && security != "--") ? "" : "";
        printf "%s %s\n", icon, ssid;
    }
}' | sort -u)

# Pega a rede ativa atualmente
active_wifi=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d':' -f2)
if [ -n "$active_wifi" ]; then
    active_entry="󰖩  Conectado a: $active_wifi"
    options="$active_entry\n$toggle\n$wifi_list"
else
    options="$toggle\n$wifi_list"
fi

# Abre o rofi
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Wi-Fi" -selected-row 1)

# Se nada foi escolhido, sai
if [ -z "$chosen" ]; then
    exit 0
fi

# Ações
if [ "$chosen" = "󰖩  Ativar Wi-Fi" ]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Wi-Fi ativado!"
elif [ "$chosen" = "󰖪  Desativar Wi-Fi" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Wi-Fi desativado!"
elif [[ "$chosen" == "󰖩  Conectado a:"* ]]; then
    ssid=$(echo "$chosen" | sed 's/󰖩  Conectado a: //')
    notify-send "Wi-Fi" "Já conectado a $ssid"
else
    # Extrai o SSID (remove o ícone  ou  do começo)
    icon=${chosen:0:1}
    ssid=${chosen:2}
    
    # Verifica se a rede já está salva
    connection_exists=$(nmcli -t -f NAME connection show | grep -x "$ssid")
    
    if [ -n "$connection_exists" ]; then
        notify-send "Wi-Fi" "Conectando a rede salva: $ssid..."
        if nmcli connection up "$ssid"; then
            notify-send "Wi-Fi" "Conectado com sucesso a $ssid!"
        else
            notify-send -u critical "Wi-Fi" "Falha ao conectar a $ssid"
        fi
    else
        # Se for protegida, pede senha
        if [ "$icon" = "" ]; then
            password=$(rofi -dmenu -password -p "Senha para $ssid: ")
            if [ -z "$password" ]; then
                exit 0
            fi
            notify-send "Wi-Fi" "Conectando a $ssid..."
            if nmcli dev wifi connect "$ssid" password "$password"; then
                notify-send "Wi-Fi" "Conectado com sucesso a $ssid!"
            else
                notify-send -u critical "Wi-Fi" "Falha ao conectar. Senha incorreta?"
            fi
        else
            # Rede aberta
            notify-send "Wi-Fi" "Conectando a $ssid..."
            if nmcli dev wifi connect "$ssid"; then
                notify-send "Wi-Fi" "Conectado com sucesso a $ssid!"
            else
                notify-send -u critical "Wi-Fi" "Falha ao conectar a $ssid"
            fi
        fi
    fi
fi
