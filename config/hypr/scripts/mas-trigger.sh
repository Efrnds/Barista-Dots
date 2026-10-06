#!/usr/bin/env bash
# ==============================================================================
# MAS TRIGGER (Prompt-Maker Hub for Hyprland & DankMaterialShell)
# ==============================================================================
set -e

PROMPT_MAKER_DIR="${PROMPT_MAKER_DIR:-$HOME/Documents/Projetos/prompt-maker}"
PROJ_ROOT="${PROJ_ROOT:-$HOME/Documents/Projetos}"
PORT="8787"
API_URL="http://127.0.0.1:${PORT}"

notify_dms() {
  local title="$1"
  local msg="$2"
  # Try DMS toast first, fallback to notify-send
  if command -v dms >/dev/null 2>&1; then
    dms ipc call toast info "${title}: ${msg}" >/dev/null 2>&1 || true
  fi
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Prompt-Maker MAS" "$title" "$msg" || true
  fi
}

# 1. Select Project Path
SELECTED_PROJECT=""
if [ -n "$1" ]; then
  SELECTED_PROJECT="$1"
else
  # Use fuzzel to pick a project directory
  PROJECTS=$(find "$PROJ_ROOT" -maxdepth 2 -mindepth 1 -type d | sort)
  SELECTED_PROJECT=$(echo "$PROJECTS" | fuzzel -d -p "📁 Escolha o Projeto: " --width 50)
fi

if [ -z "$SELECTED_PROJECT" ]; then
  exit 0
fi

# 2. Get Goal / Prompt
GOAL=""
if [ -n "$2" ]; then
  GOAL="$2"
else
  GOAL=$(echo "" | fuzzel -d -p "🎯 O que deseja fazer? " --width 60)
fi

if [ -z "$GOAL" ]; then
  exit 0
fi

notify_dms "Iniciando MAS" "Projeto: $(basename "$SELECTED_PROJECT") | $GOAL"

# 3. Ensure prompt-maker server is running
SERVER_RUNNING=$(curl -s "${API_URL}/api/jobs" >/dev/null 2>&1 && echo "yes" || echo "no")
if [ "$SERVER_RUNNING" != "yes" ]; then
  notify_dms "Servidor MAS" "Iniciando Hub em background..."
  cd "$PROMPT_MAKER_DIR"
  npm run dev:server:stable >/tmp/prompt-maker-server.log 2>&1 &
  sleep 2
fi

# 4. Dispatch Job
RESPONSE=$(curl -s -X POST "${API_URL}/api/pipeline" \
  -H "Content-Type: application/json" \
  -d "{\"projectPath\":\"$SELECTED_PROJECT\",\"goal\":\"$GOAL\",\"planner\":\"cursor\"}")

JOB_ID=$(echo "$RESPONSE" | grep -o '"jobId":"[^"]*' | cut -d'"' -f4 || true)

if [ -n "$JOB_ID" ]; then
  notify_dms "Job Criado" "ID: ${JOB_ID} — Agentes em execução no background!"
else
  notify_dms "Erro no Disparo" "$RESPONSE"
fi
