#!/bin/bash

# Script de monitoramento inteligente da bateria
# Customizado para o ThinkPad T480 (Monitora BAT0, já que BAT1 está inativa)

BAT="BAT0"

# Estados para controle de spam de notificações
NOTIFICADO_LOW=false
NOTIFICADO_CRITICAL=false
NOTIFICADO_FULL=false

while true; do
    if [ -d "/sys/class/power_supply/$BAT" ]; then
        STATUS=$(cat "/sys/class/power_supply/$BAT/status")
        CAPACITY=$(cat "/sys/class/power_supply/$BAT/capacity")

        # 1. Alerta de Bateria Crítica (<= 10% e descarregando)
        if [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -le 10 ]; then
            if [ "$NOTIFICADO_CRITICAL" = "false" ]; then
                notify-send -u critical -a "Bateria" "🔋 BATERIA CRÍTICA!" "Carga em ${CAPACITY}%. Conecte o carregador imediatamente!"
                # Tenta reproduzir um som de alerta do sistema se disponível
                paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga >/dev/null 2>&1 || aplay /usr/share/sounds/alsa/Front_Center.wav >/dev/null 2>&1
                NOTIFICADO_CRITICAL=true
            fi
        # 2. Alerta de Bateria Baixa (<= 20% e descarregando)
        elif [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -le 20 ]; then
            if [ "$NOTIFICADO_LOW" = "false" ]; then
                notify-send -u normal -a "Bateria" "🔋 Bateria Baixa" "Carga em ${CAPACITY}%. Recomenda-se conectar o carregador."
                NOTIFICADO_LOW=true
            fi
        # 3. Alerta de Carga Completa (>= 95% e carregando)
        elif [ "$STATUS" = "Charging" ] && [ "$CAPACITY" -ge 95 ]; then
            if [ "$NOTIFICADO_FULL" = "false" ]; then
                notify-send -u normal -a "Bateria" "🔌 Carga Completa" "Bateria carregada em ${CAPACITY}%. Você pode desconectar o carregador."
                NOTIFICADO_FULL=true
            fi
        fi

        # Reseta os alertas dependendo do estado
        if [ "$STATUS" = "Charging" ]; then
            NOTIFICADO_LOW=false
            NOTIFICADO_CRITICAL=false
        elif [ "$STATUS" = "Discharging" ]; then
            NOTIFICADO_FULL=false
            if [ "$CAPACITY" -gt 20 ]; then
                NOTIFICADO_LOW=false
            fi
            if [ "$CAPACITY" -gt 10 ]; then
                NOTIFICADO_CRITICAL=false
            fi
        fi
    fi

    # Checa a cada 60 segundos
    sleep 60
done
