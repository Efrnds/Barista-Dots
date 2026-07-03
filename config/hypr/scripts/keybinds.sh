#!/bin/bash

# Script dinâmico para listar os atalhos de teclado do Hyprland no Rofi
# Sobrescreve a versão antiga com suporte aprimorado a comentários explicativos de fim de linha

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    notify-send "Cheat-sheet" "Arquivo hyprland.conf não encontrado."
    exit 1
fi

# Filtra linhas de atalhos (bind/bindm) e formata para exibição
LISTA=$(grep -E "^bind[a-z]*\s*=" "$CONFIG_FILE" | while read -r line; do
    # Remove o prefixo bind/bindm e espaços
    clean_line=$(echo "$line" | sed -E 's/^bind[a-z]*\s*=\s*//')
    
    # Extrai modificador, tecla e ação
    mod=$(echo "$clean_line" | cut -d',' -f1 | sed 's/ //g')
    key=$(echo "$clean_line" | cut -d',' -f2 | sed 's/ //g')
    action=$(echo "$clean_line" | cut -d',' -f3- | sed 's/^ //')
    
    # Melhora legibilidade das variáveis comuns
    mod=$(echo "$mod" | sed 's/\$mainMod/Super/g' | sed 's/SHIFT/Shift/g' | sed 's/ALT/Alt/g' | sed 's/CTRL/Ctrl/g')
    action=$(echo "$action" | sed 's/exec,//g' | sed 's/,\s*#\s*/ ➔ /' | sed 's/^ //')

    # Trata atalhos que têm comentários explicativos no fim da linha
    if [[ "$action" == *#* ]]; then
        comentario=$(echo "$action" | cut -d'#' -f2- | sed 's/^ //')
        acao_limpa=$(echo "$action" | cut -d'#' -f1 | sed 's/ $//')
        echo "⌨️  $mod + $key  ➔  $comentario ($acao_limpa)"
    else
        # Limpa as ações comuns caso não tenham comentários
        action_pt=$action
        action_pt=$(echo "$action_pt" | sed \
            -e 's/killactive/Fechar Janela/g' \
            -e 's/togglefloating/Alternar Flutuante/g' \
            -e 's/fullscreen 1/Tela Cheia Inteligente/g' \
            -e 's/fullscreen 0/Tela Cheia Real/g' \
            -e 's/movetoworkspace/Mover para Área:/g' \
            -e 's/workspace/Mover para Workspace:/g' \
            -e 's/movefocus/Focar Janela:/g')
        echo "⌨️  $mod + $key  ➔  $action_pt"
    fi
done | sort -u)

# Mostra no Rofi como uma lista de consulta (clicar ou pressionar Enter apenas fecha)
echo -e "$LISTA" | rofi -dmenu -p "📋 Atalhos de Teclado (Super + F1)" -i -theme-str "window {width: 48%;} listview {lines: 15;}"
