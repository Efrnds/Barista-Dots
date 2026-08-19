#!/usr/bin/env bash
# Smoke tests pós install/apply (não precisa GUI completa).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

check() {
  if "$@"; then
    echo "[ok] $*"
  else
    echo "[FAIL] $*"
    failures=$((failures + 1))
  fi
}

echo "=== smoke.sh ==="

for cmd in hyprland foot tmux dms; do
  check command -v "$cmd"
done
check pacman -Qi ly

check test -f "$HOME/.config/hypr/hyprland.lua"
check test -x "$HOME/.local/bin/foot-tmux.sh"
check test -f "$HOME/.config/foot/foot.ini"
check grep -q "^shell=$HOME" "$HOME/.config/foot/foot.ini"
check test -f "$HOME/.config/dotfiles/user.conf"
check test -x "$DOTFILES/doctor.sh"
check test -x "$DOTFILES/hooks/render-config.sh"
check test -f "$DOTFILES/templates/foot.ini.in"

if systemctl is-enabled ly@tty1.service &>/dev/null; then
  check systemctl is-enabled ly@tty1.service
else
  echo "[skip] ly@tty1 (rode setup-session.sh como sudo)"
fi

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] && command -v hyprctl >/dev/null 2>&1; then
  check hyprctl version
  check test -x "$HOME/.config/hypr/scripts/launch_terminal.sh"
fi

if ! rg -q '/home/eduardo' "$DOTFILES/config" "$DOTFILES/templates" \
  -g '!config/foot/foot.ini' -g '!config/spicetify/config-xpui.ini' 2>/dev/null; then
  echo "[ok] sem paths hardcoded /home/eduardo"
else
  echo "[FAIL] paths hardcoded encontrados"
  failures=$((failures + 1))
fi

if [[ "$failures" -eq 0 ]]; then
  echo "=== smoke OK ==="
  exit 0
fi

echo "=== smoke FAILED ($failures) ==="
exit 1
