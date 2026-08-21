#!/usr/bin/env bash
# Wi-Fi via EWW picker (substitui Rofi)
set -euo pipefail
PICKER="$HOME/.config/hypr/scripts/picker.sh"

notify-send -t 1500 "Rede" "Escaneando redes Wi-Fi disponíveis..."

wifi_status=$(nmcli -fields WIFI g | tail -n 1 | tr -d '[:space:]')
if [ "$wifi_status" = "enabled" ]; then
    toggle="󰖪  Desativar Wi-Fi"
else
    toggle="󰖩  Ativar Wi-Fi"
fi

wifi_list=$(nmcli --fields "SECURITY,SSID" device wifi list | tail -n +2 | \
awk -F'  +' '{
    security = $1; ssid = $2;
    if (ssid != "" && ssid != "--") {
        icon = (security != "" && security != "--") ? "" : "";
        printf "%s %s\n", icon, ssid;
    }
}' | sort -u)

active_wifi=$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1=="yes"{print $2; exit}')
if [ -n "$active_wifi" ]; then
    options="󰖩  Conectado a: $active_wifi"$'\n'"$toggle"$'\n'"$wifi_list"
else
    options="$toggle"$'\n'"$wifi_list"
fi

chosen=$(printf '%s\n' "$options" | "$PICKER" -p "Wi-Fi")
[ -z "$chosen" ] && exit 0

if [ "$chosen" = "󰖩  Ativar Wi-Fi" ]; then
    nmcli radio wifi on
    notify-send "Wi-Fi" "Wi-Fi ativado!"
elif [ "$chosen" = "󰖪  Desativar Wi-Fi" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Wi-Fi desativado!"
elif [[ "$chosen" == "󰖩  Conectado a:"* ]]; then
    ssid=${chosen#󰖩  Conectado a: }
    notify-send "Wi-Fi" "Já conectado a $ssid"
else
    icon=${chosen:0:1}
    ssid=${chosen:2}
    if nmcli -t -f NAME connection show | grep -qx "$ssid"; then
        notify-send "Wi-Fi" "Conectando a rede salva: $ssid..."
        if nmcli connection up "$ssid"; then
            notify-send "Wi-Fi" "Conectado a $ssid"
        else
            notify-send -u critical "Wi-Fi" "Falha ao conectar a $ssid"
        fi
    elif [ "$icon" = "" ]; then
        password=$("$PICKER" --password -p "Senha para $ssid")
        [ -z "$password" ] && exit 0
        notify-send "Wi-Fi" "Conectando a $ssid..."
        if nmcli dev wifi connect "$ssid" password "$password"; then
            notify-send "Wi-Fi" "Conectado a $ssid"
        else
            notify-send -u critical "Wi-Fi" "Falha ao conectar. Senha incorreta?"
        fi
    else
        notify-send "Wi-Fi" "Conectando a $ssid..."
        if nmcli dev wifi connect "$ssid"; then
            notify-send "Wi-Fi" "Conectado a $ssid"
        else
            notify-send -u critical "Wi-Fi" "Falha ao conectar a $ssid"
        fi
    fi
fi
