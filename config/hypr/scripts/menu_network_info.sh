#!/bin/bash

# Informações de rede detalhadas via EWW picker (somente leitura)

PICKER="$HOME/.config/hypr/scripts/picker.sh"

INTERFACE=$(ip route show | grep default | awk '{print $5}')
IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}')
[ -z "$IP_LOCAL" ] && IP_LOCAL="Desconectado"

GATEWAY=$(ip route show | grep default | awk '{print $3}')
[ -z "$GATEWAY" ] && GATEWAY="Nenhum"

DNS=$(grep nameserver /etc/resolv.conf | awk 'NR==1 {print $2}')
[ -z "$DNS" ] && DNS="Nenhum"

IP_PUBLICO=$(curl --connect-timeout 2 -s https://api.ipify.org)
[ -z "$IP_PUBLICO" ] && IP_PUBLICO="Sem conexão externa"

INFO="📡 Interface: $INTERFACE
🏠 IP Local: $IP_LOCAL
🚪 Gateway: $GATEWAY
🔍 Servidor DNS: $DNS
🌍 IP Público: $IP_PUBLICO"

echo -e "$INFO" | "$PICKER" -p "ℹ️ Informações de Rede" >/dev/null
