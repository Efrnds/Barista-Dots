#!/usr/bin/env bash
# Relatório de saúde do stack Barista Dots (niri + DMS + Alacritty).
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

section "Barista Dots — doctor (niri)"

section "Binários core"
for cmd in niri niri-session alacritty tmux dms thunar; do
  if command -v "$cmd" >/dev/null 2>&1; then pass "$cmd"; else fail "$cmd ausente"; fi
done
if pacman -Qi greetd &>/dev/null; then pass "greetd"; else warn "greetd não instalado"; fi
if command -v dms-greeter >/dev/null 2>&1; then pass "dms-greeter"; else warn "dms-greeter ausente (AUR: greetd-dms-greeter-bin)"; fi
if pacman -Qi dms-shell &>/dev/null; then pass "dms-shell"; else fail "dms-shell"; fi
if pacman -Qi hyprland &>/dev/null; then warn "hyprland ainda instalado — rode ./migrate-stack.sh"; fi
if pacman -Qi foot &>/dev/null; then warn "foot ainda instalado (obsoleto)"; fi
if pacman -Qi yazi &>/dev/null; then warn "yazi ainda instalado (obsoleto)"; fi

section "Symlinks / configs"
if [[ -L "$HOME/.config/niri" || -d "$HOME/.config/niri" ]]; then pass "$HOME/.config/niri"; else fail "$HOME/.config/niri"; fi
if [[ -f "$HOME/.config/niri/config.kdl" ]]; then pass "config.kdl"; else fail "config.kdl"; fi
if [[ -f "$HOME/.config/alacritty/alacritty.toml" ]]; then pass "alacritty.toml"; else fail "alacritty.toml"; fi
if [[ -L "$HOME/.config/scripts" || -d "$HOME/.config/scripts" ]]; then pass "scripts/"; else fail "scripts/"; fi
if [[ -f "$HOME/.config/dotfiles/user.conf" ]]; then pass "user.conf"; else warn "user.conf ausente (será criado no apply)"; fi

if rg -q 'alacritty-tmux\.sh' "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null; then
  pass "alacritty shell -> alacritty-tmux.sh"
else
  warn "alacritty shell não aponta para alacritty-tmux.sh"
fi

if [[ -x "$HOME/.local/bin/alacritty-tmux.sh" ]]; then
  pass "alacritty-tmux.sh"
else
  fail "alacritty-tmux.sh ausente"
fi

if rg -q '/home/eduardo' "$DOTFILES/config" "$DOTFILES/templates" \
  -g '!config/alacritty/alacritty.toml' \
  -g '!config/spicetify/config-xpui.ini' \
  -g '!config/gtk-3.0/bookmarks' 2>/dev/null; then
  fail "paths hardcoded /home/eduardo no repo config/"
else
  pass "sem /home/eduardo hardcoded no repo"
fi

section "Session manager (greetd + DMS greeter)"
if systemctl is-enabled greetd.service &>/dev/null; then
  pass "greetd.service enabled"
else
  warn "greetd não enabled — rode: sudo dms-greeter install"
fi
if systemctl is-enabled 'ly@tty1.service' &>/dev/null; then
  warn "ly@tty1 ainda enabled (conflito) — disable ly"
fi
if [[ -f /usr/share/wayland-sessions/niri.desktop ]]; then
  pass "sessão niri.desktop"
else
  warn "niri.desktop ausente em wayland-sessions"
fi

section "Scripts de launch"
for s in launch_terminal.sh launch_or_focus.sh launch_cursor.sh toggle_zen_browser.sh; do
  if [[ -x "$HOME/.config/scripts/$s" ]]; then pass "$s"; else fail "$s não executável"; fi
done

section "niri (sessão ativa)"
if command -v niri >/dev/null 2>&1 && [[ -n "${NIRI_SOCKET:-}" ]]; then
  if niri validate 2>/dev/null; then pass "niri validate"; else warn "niri validate falhou"; fi
else
  info "Fora de sessão niri — pulando checks ao vivo"
fi

section "Apps opcionais"
if command -v zen-browser >/dev/null; then pass "zen-browser"; else warn "zen-browser (Super+B)"; fi
if [[ -x "${HOME}/Applications/cursor.AppImage" ]]; then pass "cursor AppImage"; else warn "cursor (Super+C)"; fi

section "Resumo"
if [[ "$errors" -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}OK${RESET} — $warnings aviso(s)"
  exit 0
else
  echo -e "${RED}${BOLD}$errors erro(s)${RESET}, $warnings aviso(s)"
  echo "Sugestões:"
  echo "  ~/dotfiles/migrate-stack.sh --yes"
  echo "  ~/dotfiles/apply.sh"
  echo "  ~/dotfiles/hooks/setup-session.sh"
  exit 1
fi
