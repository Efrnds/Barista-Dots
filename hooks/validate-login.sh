#!/usr/bin/env bash
# Valida pré-requisitos do Ly/PAM (evita "failed to initialize user" na outra máquina).
set -euo pipefail

warn() { echo "[validate-login] AVISO: $*"; }
ok() { echo "[validate-login] ok: $*"; }

USER_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
HOME_DIR="$(getent passwd "$USER" | cut -d: -f6)"

if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
  warn "home directory inexistente: $HOME_DIR"
else
  ok "home $HOME_DIR"
fi

if [[ -z "$USER_SHELL" || ! -x "$USER_SHELL" ]]; then
  warn "shell inválido no /etc/passwd: '${USER_SHELL:-vazio}'"
  if [[ -x /bin/zsh ]]; then
    echo "[validate-login] corrigindo -> /bin/zsh"
    sudo -A chsh -s /bin/zsh "$USER" || true
  elif [[ -x /usr/bin/zsh ]]; then
    sudo -A chsh -s /usr/bin/zsh "$USER" || true
  else
    echo "[validate-login] instalando zsh..."
    sudo -A pacman -S --needed --noconfirm zsh || true
    sudo -A chsh -s /usr/bin/zsh "$USER" 2>/dev/null || sudo -A chsh -s /bin/bash "$USER" || true
  fi
else
  ok "shell $USER_SHELL"
fi

if [[ ! -x /usr/bin/start-hyprland ]]; then
  warn "start-hyprland ausente — instale dms-shell-hyprland (ou dms-shell + hyprland)"
fi

if [[ ! -f "$HOME/.config/hypr/hyprland.lua" ]]; then
  warn "hyprland.lua ausente — rode ~/dotfiles/apply.sh"
fi

if ! pacman -Qi ly &>/dev/null; then
  warn "ly não instalado"
fi
