#!/bin/bash

# Script de Limpeza Inteligente do Arch Linux
# Executa limpeza de cache, logs do sistema, pacotes órfãos e lixo do usuário

# Verifica se notify-send está disponível
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 4000 "Faxina do Sistema" "$1"
    fi
}

echo "=== Iniciando Faxina do Sistema ==="
notify "Iniciando limpeza profunda do sistema... 🧹"

# 1. Armazena o espaço em disco antes da limpeza
ESPACIO_ANTES=$(df / -h | awk 'NR==2 {print $4}')
BYTES_ANTES=$(df / -B1 | awk 'NR==2 {print $4}')

# 2. Remover pacotes órfãos (se houver)
echo "-> Verificando pacotes órfãos..."
ORPHANS=$(pacman -Qtdq)
if [ -n "$ORPHANS" ]; then
    echo "Removendo pacotes órfãos..."
    sudo pacman -Rns --noconfirm $ORPHANS
else
    echo "Nenhum pacote órfão encontrado."
fi

# 3. Limpeza do cache do Pacman (mantém os pacotes instalados, limpa os antigos)
echo "-> Limpando cache do Pacman..."
sudo pacman -Sc --noconfirm

# 4. Limpeza do cache do Yay (AUR)
echo "-> Limpando cache do Yay..."
if command -v yay >/dev/null 2>&1; then
    yay -Sc --noconfirm
fi

# 5. Limpeza de logs antigos do Systemd Journal (limita a 7 dias de logs)
echo "-> Limpando logs antigos do Journald..."
sudo journalctl --vacuum-time=7d

# 6. Limpando cache de miniaturas (thumbnails) do usuário
echo "-> Limpando cache de miniaturas de imagens..."
rm -rf "$HOME/.cache/thumbnails"/*

# 7. Limpando a lixeira do usuário (se houver)
echo "-> Esvaziando a lixeira..."
if command -v trash-empty >/dev/null 2>&1; then
    trash-empty
else
    rm -rf "$HOME/.local/share/Trash"/*
fi

# 8. Calcula o espaço depois da limpeza
ESPACIO_DEPOIS=$(df / -h | awk 'NR==2 {print $4}')
BYTES_DEPOIS=$(df / -B1 | awk 'NR==2 {print $4}')

# Calcula a diferença
DIF_BYTES=$((BYTES_DEPOIS - BYTES_ANTES))

# Formata o tamanho liberado de forma legível
if [ $DIF_BYTES -le 0 ]; then
    MSG="Faxina concluída! Espaço livre atual: $ESPACIO_DEPOIS."
else
    # Converte bytes para formato legível (MB ou GB)
    if [ $DIF_BYTES -ge 1073741824 ]; then
        TAM_LIBERADO=$(echo "scale=2; $DIF_BYTES / 1073741824" | bc)
        MSG="Faxina concluída! Liberado ${TAM_LIBERADO} GB. Espaço livre atual: $ESPACIO_DEPOIS."
    else
        TAM_LIBERADO=$(echo "scale=2; $DIF_BYTES / 1048576" | bc)
        MSG="Faxina concluída! Liberado ${TAM_LIBERADO} MB. Espaço livre atual: $ESPACIO_DEPOIS."
    fi
fi

echo "=== $MSG ==="
notify "$MSG 🎉"
