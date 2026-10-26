#!/usr/bin/env bash
# Valida pré-requisitos do Ly/PAM e stack Barista Dots (niri).
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

if [[ ! -x /usr/bin/niri-session ]]; then
  fail "niri-session ausente — instale niri"
else
  ok "niri-session"
fi

if [[ ! -f "$HOME/.config/niri/config.kdl" ]]; then
  fail "niri config.kdl ausente — rode ~/dotfiles/apply.sh"
else
  ok "niri config.kdl"
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

if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then
  ok "alacritty.toml"
else
  fail "alacritty.toml ausente — rode apply.sh"
fi

if [[ -x "$HOME/.local/bin/alacritty-tmux.sh" ]]; then
  ok "alacritty-tmux.sh"
else
  fail "alacritty-tmux.sh ausente em ~/.local/bin"
fi

if command -v dms >/dev/null 2>&1; then
  ok "dms no PATH"
else
  fail "dms não encontrado"
fi

if [[ -x "$HOME/.config/scripts/launch_terminal.sh" ]]; then
  ok "launch_terminal.sh"
fi

if command -v thunar &>/dev/null; then ok "thunar"; else warn "thunar ausente"; fi
if command -v zen-browser &>/dev/null; then ok "zen-browser"; else warn "zen-browser ausente (opcional)"; fi
if [[ -x "${HOME}/Applications/cursor.AppImage" ]]; then ok "cursor AppImage"; else warn "cursor AppImage ausente (opcional)"; fi

exit "$ERR"
