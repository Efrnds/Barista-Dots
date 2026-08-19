#!/usr/bin/env bash
# Garante display manager / session manager no boot (ly ou DMS greeter).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$ROOT/session.conf" ]] && source "$ROOT/session.conf"
SESSION_MANAGER="${SESSION_MANAGER:-auto}"
LY_TTY="${LY_TTY:-tty1}"

need_sudo() {
  if [[ "$EUID" -ne 0 ]]; then
    sudo -A "$@"
  else
    "$@"
  fi
}

deploy_ly_config() {
  local src="$ROOT/etc/ly/config.ini"
  [[ -f "$src" ]] || return 0
  echo "[session] deploy /etc/ly/config.ini"
  need_sudo mkdir -p /etc/ly
  need_sudo cp -a "$src" /etc/ly/config.ini
}

enable_ly() {
  if ! pacman -Qi ly &>/dev/null; then
    echo "[session] ly não instalado — pulando"
    return 1
  fi

  deploy_ly_config

  local unit="ly@${LY_TTY}.service"
  echo "[session] enable $unit"
  need_sudo systemctl disable "getty@${LY_TTY}.service" 2>/dev/null || true
  need_sudo systemctl enable "$unit"
  need_sudo systemctl set-default graphical.target 2>/dev/null || true

  # ly 1.x não usa display-manager.service; desabilita outros DMs se existirem
  for other in sddm gdm lightdm greetd; do
    need_sudo systemctl disable "$other" 2>/dev/null || true
  done

  echo "[session] ly ok ($(systemctl is-enabled "$unit" 2>/dev/null || echo unknown))"
  return 0
}

enable_dms_greeter() {
  if ! command -v dms >/dev/null 2>&1; then
    echo "[session] dms não encontrado"
    return 1
  fi
  if ! pacman -Qi greetd &>/dev/null 2>&1; then
    echo "[session] greetd não instalado"
    return 1
  fi

  echo "[session] DMS greeter (greetd)"
  need_sudo dms greeter install -y 2>/dev/null || need_sudo dms greeter enable 2>/dev/null || true
  need_sudo systemctl enable greetd
  need_sudo systemctl set-default graphical.target 2>/dev/null || true
  return 0
}

resolve_manager() {
  case "$SESSION_MANAGER" in
    ly) echo ly ;;
    dms-greeter|dms) echo dms-greeter ;;
    auto)
      if pacman -Qi greetd &>/dev/null 2>&1 && command -v dms >/dev/null 2>&1; then
        echo dms-greeter
      elif pacman -Qi ly &>/dev/null; then
        echo ly
      else
        echo none
      fi
      ;;
    *) echo none ;;
  esac
}

main() {
  local mgr
  mgr="$(resolve_manager)"
  echo "[session] manager=$mgr (config=$SESSION_MANAGER)"

  case "$mgr" in
    ly) enable_ly ;;
    dms-greeter) enable_dms_greeter ;;
    none)
      echo "[session] nenhum session manager detectado/configurado"
      return 0
      ;;
  esac
}

main "$@"
