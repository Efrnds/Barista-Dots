#!/bin/bash

# Script interativo de gerenciamento de notificações usando Rofi e Mako

# Pega o status do Não Perturbe (DND)
if makoctl mode | grep -q "dnd"; then
    DND_STATUS="Ativo"
    DND_TOGGLE="  Desativar Não Perturbe"
else
    DND_STATUS="Inativo"
    DND_TOGGLE="  Ativar Não Perturbe"
fi

# Opções de controle no topo do menu
CONTROL_OPTIONS="$DND_TOGGLE
  Limpar todas as notificações"

# Obtém notificações ativas e formata (usa jq para parsear o JSON)
ACTIVE_NOTIFS=$(makoctl list -j | jq -r '.[] | "🔔 [Ativa] (\(.id)) \(.app_name): \(.summary) - \(.body // "")"')

# Obtém histórico de notificações passadas e formata
HISTORY_NOTIFS=$(makoctl history -j | jq -r '.[] | "📜 [Histórico] (\(.id)) \(.app_name): \(.summary) - \(.body // "")"')

# Junta as listas e remove linhas em branco
FULL_LIST=$(echo -e "$CONTROL_OPTIONS\n$ACTIVE_NOTIFS\n$HISTORY_NOTIFS" | sed '/^$/d')

# Exibe o menu no Rofi
CHOSEN=$(echo -e "$FULL_LIST" | rofi -dmenu -i -p "🔔 Notificações (Não Perturbe: $DND_STATUS)" -theme-str 'window {width: 45%;} listview {lines: 12;}')

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if [ "$CHOSEN" = "  Ativar Não Perturbe" ]; then
    makoctl mode -s dnd
    notify-send -t 1500 "Não Perturbe" "Ativado "
elif [ "$CHOSEN" = "  Desativar Não Perturbe" ]; then
    makoctl mode -s default
    notify-send -t 1500 "Não Perturbe" "Desativado "
elif [ "$CHOSEN" = "  Limpar todas as notificações" ]; then
    makoctl dismiss -a
    notify-send -t 1500 "Notificações" "Todas as notificações foram limpas "
else
    # Extrai o ID numérico de dentro dos parênteses (ex: "(83)")
    ID=$(echo "$CHOSEN" | grep -oP '\(\K[0-9]+(?=\))')
    
    if [ -n "$ID" ]; then
        # Descarta a notificação individual pelo ID
        makoctl dismiss -n "$ID"
        # Reabre o script para mostrar a lista atualizada
        exec "$0"
    fi
fi
