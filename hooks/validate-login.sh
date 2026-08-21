#!/usr/bin/env bash
# Valida pré-requisitos do Ly/PAM e stack Barista Dots.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERR=0

warn() { echo "[validate-login] AVISO: $*"; }
fail() { echo "[validate-login] ERRO: $*"; ERR=1; }
ok() { echo "[validate-login] ok: $*"; }

USER_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
HOME_DIR="$(getent passwd "$USER" | cut -d: -f6)"

if [[ -z "$HOME_DIR" || ! -d "$HOME_DIR" ]]; then
  fail "home directory inexistente: ${HOME_DIR:-vazio}"
else
  ok "home $HOME_DIR"
fi

if [[ -z "$USER_SHELL" || ! -x "$USER_SHELL" ]]; then
  fail "shell inválido no /etc/passwd: '${USER_SHELL:-vazio}'"
  if [[ -x /usr/bin/zsh ]]; then
    echo "[validate-login] tentando corrigir -> /usr/bin/zsh"
    sudo -A chsh -s /usr/bin/zsh "$USER" || true
  fi
else
  ok "shell $USER_SHELL"
fi

if [[ ! -x /usr/bin/start-hyprland ]]; then
  fail "start-hyprland ausente — instale dms-shell-hyprland"
else
  ok "start-hyprland"
fi

if [[ ! -f "$HOME/.config/hypr/hyprland.lua" ]]; then
  fail "hyprland.lua ausente — rode ~/dotfiles/apply.sh"
else
  ok "hyprland.lua"
fi

if ! pacman -Qi ly &>/dev/null; then
  warn "ly não instalado"
else
  ok "ly instalado"
  unit="ly@tty1.service"
  if systemctl is-enabled "$unit" &>/dev/null; then
    ok "$unit enabled"
  else
    warn "$unit não enabled — rode hooks/setup-session.sh"
  fi
fi

FOOT_SHELL="$(grep -E '^shell=' "$HOME/.config/foot/foot.ini" 2>/dev/null | cut -d= -f2- || true)"
if [[ -n "$FOOT_SHELL" && -x "$FOOT_SHELL" ]]; then
  ok "foot shell executável ($FOOT_SHELL)"
elif [[ -n "$FOOT_SHELL" ]]; then
  fail "foot shell não executável: $FOOT_SHELL"
else
  warn "foot.ini shell não encontrado — rode apply.sh"
fi

if [[ -x "$HOME/.local/bin/foot-tmux.sh" ]]; then
  ok "foot-tmux.sh"
else
  fail "foot-tmux.sh ausente em ~/.local/bin"
fi

if command -v dms >/dev/null 2>&1; then
  ok "dms no PATH"
else
  fail "dms não encontrado"
fi

if command -v "$HOME/.config/hypr/scripts/launch_terminal.sh" &>/dev/null; then
  ok "launch_terminal.sh"
fi

if command -v zen-browser &>/dev/null; then ok "zen-browser"; else warn "zen-browser ausente (opcional)"; fi
if [[ -x "${HOME}/Applications/cursor.AppImage" ]]; then ok "cursor AppImage"; else warn "cursor AppImage ausente (opcional)"; fi

exit "$ERR"
