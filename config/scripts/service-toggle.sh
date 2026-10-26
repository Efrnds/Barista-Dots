#!/usr/bin/env bash
# Toggle serviços sob demanda: warp | dropbox | docker
set -euo pipefail

SCRIPTS="${HOME}/.config/scripts"
PICKER="${SCRIPTS}/picker.sh"

toast() {
  local msg="$1"
  if command -v dms >/dev/null 2>&1; then
    dms ipc call toast info "$msg" >/dev/null 2>&1 || notify-send "Serviços" "$msg"
  else
    notify-send "Serviços" "$msg"
  fi
}

need_sudo() {
  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    "$@"
  fi
}

is_active() {
  systemctl is-active --quiet "$1" 2>/dev/null
}

dropbox_running() {
  pgrep -x dropbox >/dev/null 2>&1 || pgrep -f '[.]dropbox-dist/dropbox' >/dev/null 2>&1
}

status_line() {
  local name="$1" state="$2"
  if [[ "$state" == on ]]; then
    printf '%s  ● ligado\n' "$name"
  else
    printf '%s  ○ desligado\n' "$name"
  fi
}

warp_state() {
  if is_active warp-svc; then echo on; else echo off; fi
}

docker_state() {
  if is_active docker; then echo on; else echo off; fi
}

dropbox_state() {
  if dropbox_running; then echo on; else echo off; fi
}

toggle_warp() {
  if is_active warp-svc; then
    need_sudo systemctl stop warp-svc.service
    toast "WARP parado"
  else
    need_sudo systemctl start warp-svc.service
    # reconecta se warp-cli existir
    if command -v warp-cli >/dev/null 2>&1; then
      sleep 1
      warp-cli connect >/dev/null 2>&1 || warp-cli --accept-tos connect >/dev/null 2>&1 || true
    fi
    toast "WARP iniciado"
  fi
}

toggle_docker() {
  if is_active docker; then
    need_sudo systemctl stop docker.service docker.socket
    toast "Docker parado"
  else
    need_sudo systemctl start docker.service
    toast "Docker iniciado"
  fi
}

toggle_dropbox() {
  if dropbox_running; then
    pkill -f '[.]dropbox-dist/dropbox' 2>/dev/null || pkill -x dropbox 2>/dev/null || true
    toast "Dropbox parado"
  else
    if command -v dropbox >/dev/null 2>&1; then
      dropbox &
      disown || true
    elif [[ -x "$HOME/.dropbox-dist/dropboxd" ]]; then
      "$HOME/.dropbox-dist/dropboxd" &
      disown || true
    else
      toast "Dropbox não encontrado"
      return 1
    fi
    toast "Dropbox iniciado"
  fi
}

menu() {
  local choice
  choice=$(printf '%s\n' \
    "$(status_line 'WARP' "$(warp_state)")" \
    "$(status_line 'Dropbox' "$(dropbox_state)")" \
    "$(status_line 'Docker' "$(docker_state)")" \
    "Voltar" \
    | "$PICKER" -p "Serviços")
  case "$choice" in
    WARP*) toggle_warp ;;
    Dropbox*) toggle_dropbox ;;
    Docker*) toggle_docker ;;
    *) return 0 ;;
  esac
}

case "${1:-menu}" in
  menu) menu ;;
  warp) toggle_warp ;;
  dropbox) toggle_dropbox ;;
  docker) toggle_docker ;;
  *)
    echo "uso: $0 [menu|warp|dropbox|docker]" >&2
    exit 2
    ;;
esac
