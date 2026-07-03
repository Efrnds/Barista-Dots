#!/bin/bash

# Define onde a imagem vai ser salva persistentemente
WALL_DIR="$HOME/.config/hypr"
WALL_PATH="$WALL_DIR/current_wallpaper.jpg"
TEMP_PATH="/tmp/next_wallpaper.jpg"
HISTORY_FILE="$HOME/.cache/mudar_fundo_history.txt"
INFO_FILE="$HOME/.cache/current_wallpaper_info.txt"
FAV_DIR="$HOME/Pictures/Wallpapers/Favoritos"

# Cores dinâmicas baseadas no tema ativo do sistema (Lavender ou Catppuccin Macchiato)
ACTIVE_THEME="lavender"
if [ -f "$HOME/.config/active_theme" ]; then
    ACTIVE_THEME=$(cat "$HOME/.config/active_theme")
fi

if [ "$ACTIVE_THEME" = "macchiato" ]; then
    # Catppuccin Macchiato: Roxo/Mauve, Lavanda, Azul, Rosa, Cinza Escuro/Base
    COLORS="c6a0f6,b7bdf8,8cadfa,f5bde6,24273a"
else
    # Lavender Dream: Lavanda, Roxo Pastel, Indigo/Escuro, Roxo Clássico, Rosa Pastel
    COLORS="a6b1e1,dcd6f7,424874,663399,ea4c88"
fi

# Lista de temas bonitos e populares para escolher aleatoriamente
THEMES=("minimalism" "cyberpunk" "synthwave" "space" "pixelart" "landscape" "nature" "vector" "lofi" "retrowave" "cozy" "nord" "dark" "scenery")

# Sub-comando: CURTIR/LIKE o wallpaper atual
like_current_wallpaper() {
    if [ ! -f "$WALL_PATH" ]; then
        echo "Erro: Nenhum wallpaper atual encontrado em $WALL_PATH."
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -u critical "Erro" "Nenhum wallpaper atual encontrado."
        fi
        exit 1
    fi

    local WALL_ID="desconhecido"
    local WALL_URL=""
    local WALL_RES="desconhecida"
    local ext="jpg"

    # Carrega as informações do wallpaper atual
    if [ -f "$INFO_FILE" ]; then
        source "$INFO_FILE" 2>/dev/null
    fi

    # Verifica se já é local
    if [[ "$WALL_ID" =~ ^local_ ]]; then
        echo "Este wallpaper já é um favorito local!"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Papel de Parede" "Este wallpaper já está nos seus favoritos!"
        fi
        exit 0
    fi

    # Determina a extensão a partir da URL se possível
    if [ -n "$WALL_URL" ]; then
        ext="${WALL_URL##*.}"
    fi

    # Cria pasta de favoritos se não existir
    mkdir -p "$FAV_DIR"

    local dest_file="$FAV_DIR/wallhaven-${WALL_ID}.${ext}"

    if [ -f "$dest_file" ]; then
        echo "Este wallpaper já foi curtido anteriormente! ($dest_file)"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Papel de Parede" "Este wallpaper já está nos favoritos!"
        fi
        exit 0
    fi

    # Copia o arquivo atual para os favoritos
    cp "$WALL_PATH" "$dest_file"

    echo "Wallpaper curtido! Salvo em: $dest_file"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Wallpaper Curtido!" "Salvo em: Imagens/Wallpapers/Favoritos/\nID: $WALL_ID"
    fi

    # Atualiza o arquivo de informações indicando que agora é local
    echo "WALL_ID='local_wallhaven_${WALL_ID}'" > "$INFO_FILE"
    echo "WALL_RES='${WALL_RES}'" >> "$INFO_FILE"
    echo "WALL_URL=''" >> "$INFO_FILE"
    echo "WALL_STRATEGY='Local Favorito'" >> "$INFO_FILE"

    exit 0
}

# Sub-comando: Aplicar um wallpaper dos FAVORITOS locais
apply_local_wallpaper() {
    if [ ! -d "$FAV_DIR" ] || [ -z "$(ls -A "$FAV_DIR" 2>/dev/null)" ]; then
        echo "Você ainda não curtiu nenhum wallpaper!"
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -u critical "Erro" "Você não tem wallpapers curtidos nos favoritos locais."
        fi
        exit 1
    fi

    # Sorteia uma imagem na pasta de favoritos
    local random_fav=$(find "$FAV_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.svg" \) 2>/dev/null | shuf -n 1)

    if [ -z "$random_fav" ]; then
        echo "Nenhum arquivo de imagem válido encontrado nos favoritos."
        exit 1
    fi

    local filename=$(basename "$random_fav")
    local fav_id="${filename%.*}"

    # Aplica o wallpaper
    cp "$random_fav" "$WALL_PATH"
    awww img "$WALL_PATH" --transition-type wipe --transition-angle 30 --transition-step 90

    # Salva informações locais
    echo "WALL_ID='local_${fav_id}'" > "$INFO_FILE"
    echo "WALL_RES='local'" >> "$INFO_FILE"
    echo "WALL_URL=''" >> "$INFO_FILE"
    echo "WALL_STRATEGY='Local Favorito'" >> "$INFO_FILE"

    echo "Wallpaper local aplicado: $filename"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Papel de Parede Local" "Aplicado: $filename"
    fi
    exit 0
}

# Parse de argumentos
USE_COLORS=true
QUERY=""

for arg in "$@"; do
    case $arg in
        --nocolor|-nc)
            USE_COLORS=false
            shift
            ;;
        --like|-l|--curtir|-c)
            like_current_wallpaper
            ;;
        --local|-loc)
            apply_local_wallpaper
            ;;
        --help|-h)
            echo "Uso: $0 [opções] [tema]"
            echo "Opções:"
            echo "  -nc, --nocolor    Ignora o filtro de cores (traz mais variedade)"
            echo "  -l, --like        Curte o wallpaper atual e o salva nos favoritos locais"
            echo "  -loc, --local     Aplica um wallpaper aleatório dos seus favoritos locais"
            echo "  -h, --help        Mostra esta ajuda"
            echo "Temas comuns: cyberpunk, pixelart, space, minimalism, lofi, etc."
            exit 0
            ;;
        *)
            QUERY="$arg"
            shift
            ;;
    esac
done

# Se nenhum tema foi passado por argumento, escolhe um aleatório (ou local com chance de 15%)
if [ -z "$QUERY" ]; then
    # Se existirem favoritos, dá 15% de chance de sortear um favorito local
    if [ -d "$FAV_DIR" ] && [ -n "$(ls -A "$FAV_DIR" 2>/dev/null)" ] && [ $((RANDOM % 100)) -lt 15 ]; then
        echo "Sorteado: Carregando wallpaper dos favoritos locais..."
        apply_local_wallpaper
    fi

    # 75% de chance de pegar um tema da lista, 25% de buscar geral (toplist puro)
    if [ $((RANDOM % 4)) -ne 0 ]; then
        RANDOM_INDEX=$((RANDOM % ${#THEMES[@]}))
        QUERY="${THEMES[$RANDOM_INDEX]}"
    fi
fi

# Função para codificar strings para URL usando jq
urlencode() {
    jq -rn --arg x "$1" '$x|@uri'
}

# Função para fazer a busca na API do Wallhaven
fetch_wallpapers() {
    local q="$1"
    local use_color="$2"
    local page="$3"
    local sorting="$4"

    # Buscamos wallpapers com resolução mínima de 1080p e aspect ratio de monitor (16:9 ou 16:10)
    # Isso evita imagens verticais de celular ou quadradas
    local api_url="https://wallhaven.cc/api/v1/search?atleast=1920x1080&ratios=16x9,16x10"

    # Categorias: General (1), Anime (1), People (0) -> 110
    api_url="${api_url}&categories=110"

    # Método de ordenação (toplist, favorites, views, hot)
    api_url="${api_url}&sorting=${sorting}"
    if [ "$sorting" = "toplist" ]; then
        api_url="${api_url}&topRange=1y" # Melhores do último ano
    fi

    # Página da busca
    api_url="${api_url}&page=${page}"

    # Adiciona a query se existir
    if [ -n "$q" ]; then
        local encoded_q=$(urlencode "$q")
        api_url="${api_url}&q=${encoded_q}"
    fi

    # Filtro de cores (se ativado)
    if [ "$use_color" = "true" ]; then
        api_url="${api_url}&colors=${COLORS}"
    fi

    # Faz a requisição
    curl -s "$api_url"
}

# Tenta criar o cache de histórico se não existir
touch "$HISTORY_FILE"

MAX_RETRIES=4
ATTEMPT=1
SUCCESS=false

# Loop de tentativas com estratégias diferentes (caso a busca venha vazia)
while [ $ATTEMPT -le $MAX_RETRIES ] && [ "$SUCCESS" = "false" ]; do
    # Varia a ordenação para trazer sempre coisas diferentes
    SORT_MODE="toplist"
    if [ $((RANDOM % 3)) -eq 0 ]; then
        SORT_MODE="favorites"
    fi

    # Sorteia uma página entre 1 e 8 para garantir aleatoriedade dos resultados bem votados
    PAGE=$((1 + RANDOM % 8))

    case $ATTEMPT in
        1)
            # Estratégia 1: Tema selecionado + Cores do sistema
            STRATEGY_DESC="Tema '$QUERY' com paleta roxo/azul"
            JSON_DATA=$(fetch_wallpapers "$QUERY" "$USE_COLORS" "$PAGE" "$SORT_MODE")
            ;;
        2)
            # Estratégia 2: Tema selecionado (sem limite de cor)
            STRATEGY_DESC="Tema '$QUERY' (cores livres)"
            JSON_DATA=$(fetch_wallpapers "$QUERY" "false" "$PAGE" "$SORT_MODE")
            ;;
        3)
            # Estratégia 3: Outro tema aleatório (sem limite de cor)
            ALT_THEME="${THEMES[$((RANDOM % ${#THEMES[@]}))]}"
            STRATEGY_DESC="Tema alternativo '$ALT_THEME' (cores livres)"
            JSON_DATA=$(fetch_wallpapers "$ALT_THEME" "false" "$PAGE" "$SORT_MODE")
            ;;
        4)
            # Estratégia 4: Wallpapers mais populares no geral (sem filtros)
            STRATEGY_DESC="Populares do Ano (Geral)"
            JSON_DATA=$(fetch_wallpapers "" "false" "$PAGE" "toplist")
            ;;
    esac

    # Extrai uma lista de imagens no formato: "id path resolution"
    WALL_LIST=$(echo "$JSON_DATA" | jq -r '.data[]? | "\(.id) \(.path) \(.resolution)"' 2>/dev/null)

    if [ -n "$WALL_LIST" ]; then
        # Filtra os wallpapers para não repetir os últimos mostrados
        SELECTED_WALL=$(echo "$WALL_LIST" | shuf | while read -r id path res; do
            if ! grep -q "$id" "$HISTORY_FILE"; then
                echo "$id $path $res"
                break
            fi
        done)

        # Se todos da página já foram usados recentemente, pega um aleatório da lista mesmo assim
        if [ -z "$SELECTED_WALL" ]; then
            SELECTED_WALL=$(echo "$WALL_LIST" | shuf -n 1)
        fi

        if [ -n "$SELECTED_WALL" ]; then
            WALL_ID=$(echo "$SELECTED_WALL" | cut -d' ' -f1)
            WALL_URL=$(echo "$SELECTED_WALL" | cut -d' ' -f2)
            WALL_RES=$(echo "$SELECTED_WALL" | cut -d' ' -f3)

            # Notifica o usuário do download (se notify-send estiver disponível)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -t 2000 "Papel de Parede" "Buscando imagem ($STRATEGY_DESC)..."
            fi

            # Tenta baixar a imagem
            if wget -qO "$TEMP_PATH" "$WALL_URL"; then
                cp "$TEMP_PATH" "$WALL_PATH"
                
                # Aplica no Hyprland usando o awww
                awww img "$WALL_PATH" --transition-type wipe --transition-angle 30 --transition-step 90
                
                # Salva informações do wallpaper atual para poder curtir depois
                echo "WALL_ID='$WALL_ID'" > "$INFO_FILE"
                echo "WALL_RES='$WALL_RES'" >> "$INFO_FILE"
                echo "WALL_URL='$WALL_URL'" >> "$INFO_FILE"
                echo "WALL_STRATEGY='$STRATEGY_DESC'" >> "$INFO_FILE"

                # Salva o ID no histórico (mantém apenas os últimos 15)
                echo "$WALL_ID" >> "$HISTORY_FILE"
                tail -n 15 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
                
                # Notifica sucesso
                if command -v notify-send >/dev/null 2>&1; then
                    notify-send "Papel de Parede Atualizado" "Tema: ${QUERY:-Geral}\nResolução: $WALL_RES"
                fi
                echo "Wallpaper atualizado! ID: $WALL_ID | Resolução: $WALL_RES | Estratégia: $STRATEGY_DESC"
                SUCCESS=true
            else
                echo "Erro ao baixar a imagem de: $WALL_URL. Tentando outra estratégia..."
            fi
        fi
    fi

    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$SUCCESS" = "false" ]; then
    echo "Não foi possível obter uma imagem da API do Wallhaven após várias tentativas."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Erro" "Não foi possível conectar ou obter uma imagem do Wallhaven."
    fi
    exit 1
fi
