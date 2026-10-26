#!/bin/bash

# Script para ligar/desligar o servidor local do Ollama (Economiza CPU/RAM)

notify() {
    notify-send -t 3000 -a "Ollama IA" "$1" "$2"
}

# Verifica se o ollama está instalado
if ! command -v ollama &>/dev/null; then
    notify "Erro" "Ollama não está instalado no sistema. Instale com: sudo pacman -S ollama"
    exit 1
fi

# Verifica se o processo do ollama está rodando
PID=$(pgrep -f "ollama serve")

if [ -n "$PID" ]; then
    # Se estiver rodando, encerra o processo
    pkill -f "ollama serve"
    notify "Desativado 🛑" "O servidor do Ollama foi encerrado. Recursos de CPU/RAM liberados."
    echo "Ollama parado."
else
    # Se não estiver rodando, inicia em background expondo a porta para o Docker
    export OLLAMA_HOST="0.0.0.0:11434"
    export OLLAMA_ORIGINS="*"
    ollama serve >/dev/null 2>&1 &
    
    # Aguarda 1 segundo e avisa o usuário
    sleep 1
    notify "Ativado 🧠" "Servidor do Ollama iniciado em segundo plano. Pronto para uso!"
    echo "Ollama iniciado."
fi
