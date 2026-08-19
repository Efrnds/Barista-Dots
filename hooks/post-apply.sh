#!/usr/bin/env bash
# Pós-apply: permissões, serviços user, fontes, reload leve.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[post-apply] chmod em scripts hypr..."
find "$HOME/.config/hypr/scripts" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
chmod +x "$HOME/.config/hypr/mudar_fundo.sh" 2>/dev/null || true
chmod +x "$ROOT/local-bin/"* 2>/dev/null || true

echo "[post-apply] systemd user..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload 2>/dev/null || true
  for unit in dms-foot-sync.path dms-foot-sync.service; do
    if [[ -f "$HOME/.config/systemd/user/$unit" ]]; then
      systemctl --user enable "$unit" 2>/dev/null || true
    fi
  done
  systemctl --user restart dms-foot-sync.path 2>/dev/null || true
fi

echo "[post-apply] sync foot <- DMS (se existir)..."
if [[ -x "$HOME/.config/hypr/scripts/sync-foot-theme-dms.sh" ]]; then
  "$HOME/.config/hypr/scripts/sync-foot-theme-dms.sh" 2>/dev/null || true
fi

echo "[post-apply] fc-cache..."
fc-cache -f >/dev/null 2>&1 || true

echo "[post-apply] hyprland reload (se sessão ativa)..."
if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]] && command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload 2>/dev/null || true
fi

echo "[post-apply] ok"
