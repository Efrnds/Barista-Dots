#!/usr/bin/env bash
# Relatório de saúde do stack Barista Dots.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m'

errors=0
warnings=0

pass() { echo -e "${GREEN}✓${RESET} $*"; }
warn() { echo -e "${YELLOW}!${RESET} $*"; warnings=$((warnings + 1)); }
fail() { echo -e "${RED}✗${RESET} $*"; errors=$((errors + 1)); }
info() { echo -e "${BLUE}→${RESET} $*"; }

section() { echo -e "\n${BOLD}$*${RESET}"; }

section "Barista Dots — doctor"

section "Binários core"
for cmd in hyprland foot tmux dms fuzzel start-hyprland; do
  if command -v "$cmd" >/dev/null 2>&1; then pass "$cmd"; else fail "$cmd ausente"; fi
done
pacman -Qi ly &>/dev/null && pass "ly (pacote)" || warn "ly não instalado"

section "Symlinks / configs"
[[ -L "$HOME/.config/hypr" || -d "$HOME/.config/hypr" ]] && pass "~/.config/hypr" || fail "~/.config/hypr"
[[ -f "$HOME/.config/hypr/hyprland.lua" ]] && pass "hyprland.lua" || fail "hyprland.lua"
[[ -f "$HOME/.config/foot/foot.ini" ]] && pass "foot.ini" || fail "foot.ini"
[[ -f "$HOME/.config/dotfiles/user.conf" ]] && pass "user.conf" || warn "user.conf ausente (será criado no apply)"

FOOT_SHELL="$(grep -E '^shell=' "$HOME/.config/foot/foot.ini" 2>/dev/null | cut -d= -f2- || true)"
if [[ -n "$FOOT_SHELL" && "$FOOT_SHELL" == "$HOME"* && -x "$FOOT_SHELL" ]]; then
  pass "foot shell path absoluto"
elif [[ -n "$FOOT_SHELL" && -x "$FOOT_SHELL" ]]; then
  pass "foot shell ok"
else
  fail "foot shell inválido: ${FOOT_SHELL:-vazio}"
fi

if rg -q '/home/eduardo' "$DOTFILES/config" "$DOTFILES/templates" \
  -g '!config/foot/foot.ini' -g '!config/spicetify/config-xpui.ini' 2>/dev/null; then
  fail "paths hardcoded /home/eduardo no repo config/"
else
  pass "sem /home/eduardo hardcoded no repo"
fi

section "Session manager (Ly)"
if pacman -Qi ly &>/dev/null; then
  pass "ly instalado"
  if systemctl is-enabled ly@tty1.service &>/dev/null; then
    pass "ly@tty1.service enabled"
  else
    warn "ly@tty1.service não enabled — rode hooks/setup-session.sh"
  fi
  if [[ -f /etc/ly/config.ini ]] && grep -q 'full_color = true' /etc/ly/config.ini; then
    pass "Ly full_color=true"
  else
    warn "Ly full_color pode estar off (tela preta)"
  fi
else
  warn "ly não instalado"
fi

section "Scripts de launch"
for s in launch_terminal.sh launch_or_focus.sh launch_cursor.sh toggle_zen_browser.sh; do
  [[ -x "$HOME/.config/hypr/scripts/$s" ]] && pass "$s" || fail "$s não executável"
done

section "Hypr binds (sessão Wayland)"
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl binds -j 2>/dev/null | python3 -c "
import json,sys
binds=json.load(sys.stdin)
t=[b for b in binds if b.get('key')=='T' and b.get('modmask')==64]
sys.exit(0 if t else 1)
" 2>/dev/null; then
    pass "Super+T registrado"
  else
    warn "Super+T não encontrado nos binds"
  fi
  if command -v dms >/dev/null 2>&1; then
    if dms ipc call hypr openBinds 2>&1 | grep -qi success; then
      pass "DMS openBinds ok"
    else
      warn "DMS openBinds falhou — binds podem estar desligados (Super+Shift+C)"
      info "Fix: dms ipc call hypr openBinds"
    fi
  fi
else
  info "Fora de sessão Wayland — pulando checks hyprctl"
fi

section "Apps opcionais"
command -v zen-browser >/dev/null && pass "zen-browser" || warn "zen-browser (Super+B)"
[[ -x "${HOME}/Applications/cursor.AppImage" ]] && pass "cursor AppImage" || warn "cursor (Super+C)"

section "Resumo"
if [[ "$errors" -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}OK${RESET} — $warnings aviso(s)"
  exit 0
else
  echo -e "${RED}${BOLD}$errors erro(s)${RESET}, $warnings aviso(s)"
  echo "Sugestões:"
  echo "  ~/dotfiles/apply.sh"
  echo "  ~/dotfiles/hooks/setup-session.sh"
  echo "  dms ipc call hypr openBinds"
  exit 1
fi
