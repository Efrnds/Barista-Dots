#!/bin/bash

# Script Rofi para exibir informações de rede detalhadas (Local e Externa)

# IP Local e Interface
INTERFACE=$(ip route show | grep default | awk '{print $5}')
IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
[ -z "$IP_LOCAL" ] && IP_LOCAL="Desconectado"

# Gateway (Roteador)
GATEWAY=$(ip route show | grep default | awk '{print $3}')
[ -z "$GATEWAY" ] && GATEWAY="Nenhum"

# Servidor DNS ativo
DNS=$(grep nameserver /etc/resolv.conf | awk 'NR==1 {print $2}')
[ -z "$DNS" ] && DNS="Nenhum"

# IP Público (com timeout de 2s para não travar se estiver offline)
IP_PUBLICO=$(curl --connect-timeout 2 -s https://api.ipify.org)
[ -z "$IP_PUBLICO" ] && IP_PUBLICO="Sem conexão externa"

# Monta o menu de texto informativo
INFO="📡 Interface: $INTERFACE\n🏠 IP Local: $IP_LOCAL\n🚪 Gateway: $GATEWAY\n🔍 Servidor DNS: $DNS\n🌍 IP Público: $IP_PUBLICO"

# Abre no Rofi (apenas informativo)
echo -e "$INFO" | rofi -dmenu -p "ℹ️ Informações de Rede" -i \
    -theme-str "window {width: 25%;} listview {lines: 5;} element {font: 'JetBrainsMono Nerd Font Bold 11';}"
