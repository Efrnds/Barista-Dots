#!/usr/bin/env bash

# Verifica status do bluetooth
bt_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [ "$bt_status" = "yes" ]; then
    toggle="󰂭  Desativar Bluetooth"
    
    # Pega lista de dispositivos pareados
    devices=$(bluetoothctl devices | awk '{print $2, substr($0, index($0,$3))}')
    
    # Monta a lista para o rofi
    device_list=""
    while read -r mac name; do
        if [ -n "$mac" ]; then
            # Verifica se está conectado
            info=$(bluetoothctl info "$mac")
            if echo "$info" | grep -q "Connected: yes"; then
                device_list="󰂱  $name (Conectado)\n$device_list"
            else
                device_list="$device_list\n󰂯  $name"
            fi
        fi
    done <<< "$devices"
    
    # Remove linhas vazias
    device_list=$(echo -e "$device_list" | grep -v '^$')
    
    options="$toggle\n󰂰  Escanear Novos Dispositivos\n$device_list"
else
    toggle="󰂯  Ativar Bluetooth"
    options="$toggle"
fi

chosen=$(echo -e "$options" | rofi -dmenu -i -p "Bluetooth" -selected-row 0)

if [ -z "$chosen" ]; then
    exit 0
fi

if [ "$chosen" = "󰂯  Ativar Bluetooth" ]; then
    bluetoothctl power on
    notify-send "Bluetooth" "Bluetooth ativado!"
elif [ "$chosen" = "󰂭  Desativar Bluetooth" ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Bluetooth desativado!"
elif [ "$chosen" = "󰂰  Escanear Novos Dispositivos" ]; then
    notify-send "Bluetooth" "Escaneando dispositivos (10s)..."
    bluetoothctl --timeout 10 scan on > /dev/null
    notify-send "Bluetooth" "Escanear finalizado. Abra o menu novamente."
elif [[ "$chosen" == *" (Conectado)" ]]; then
    # Desconecta
    name=$(echo "$chosen" | sed 's/󰂱  //; s/ (Conectado)//')
    mac=$(bluetoothctl devices | grep "$name" | awk '{print $2}')
    notify-send "Bluetooth" "Desconectando de $name..."
    bluetoothctl disconnect "$mac"
    notify-send "Bluetooth" "Desconectado de $name!"
else
    # Conecta
    name=$(echo "$chosen" | sed 's/󰂯  //')
    mac=$(bluetoothctl devices | grep "$name" | awk '{print $2}')
    notify-send "Bluetooth" "Conectando a $name..."
    if bluetoothctl connect "$mac"; then
        notify-send "Bluetooth" "Conectado a $name!"
    else
        notify-send -u critical "Bluetooth" "Falha ao conectar a $name"
    fi
fi
