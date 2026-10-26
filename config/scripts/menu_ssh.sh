#!/usr/bin/env bash
# Menu de conexões SSH (lê ~/.ssh/config) — niri / DMS

set -euo pipefail

PICKER="$HOME/.config/scripts/picker.sh"
SSH_CONFIG="${HOME}/.ssh/config"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/barista/ssh-menu.log"
APP_ID="ssh-float"

log() {
  mkdir -p "$(dirname "$LOG")"
  printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"
}

toast() {
  local kind="${1:-info}"
  local msg="${2:-}"
  if command -v dms >/dev/null 2>&1; then
    dms ipc call toast "$kind" "SSH: ${msg}" >/dev/null 2>&1 \
      || notify-send "SSH" "$msg"
  else
    notify-send "SSH" "$msg"
  fi
}

if [[ ! -f "$SSH_CONFIG" ]]; then
  toast error "Arquivo ~/.ssh/config não encontrado."
  exit 0
fi

HOSTS=$(grep -E -i '^Host[[:space:]]+' "$SSH_CONFIG" | awk '{print $2}' | grep -vE '\*' || true)

if [[ -z "${HOSTS}" ]]; then
  toast warn "Nenhum Host SSH configurado em ~/.ssh/config."
  exit 0
fi

CHOSEN=$(printf '%s\n' "$HOSTS" | "$PICKER" -p 'SSH' | tr -d '\r\n' | xargs || true)
log "chosen=[${CHOSEN}]"

if [[ -z "${CHOSEN}" ]]; then
  log "empty choice, abort"
  exit 0
fi

if [[ ! "$CHOSEN" =~ ^[A-Za-z0-9._-]+$ ]]; then
  toast error "Host inválido: ${CHOSEN}"
  log "reject invalid host=[${CHOSEN}]"
  exit 1
fi

toast info "Conectando em ${CHOSEN}…"
alacritty --class "${APP_ID}" -o "window.dimensions.columns=140" -o "window.dimensions.lines=40" -e ssh "${CHOSEN}" &
log "launched alacritty ssh ${CHOSEN}"
