#!/usr/bin/env bash
# Força o DMS a regenerar dms/colors.kdl (bordas/focus-ring) e valida o niri.
set -euo pipefail

COLORS="${HOME}/.config/niri/dms/colors.kdl"

# Reaplica o wallpaper atual → DMS roda matugen e reescreve colors.kdl
wp=""
if command -v dms >/dev/null 2>&1; then
  wp=$(dms ipc call wallpaper get 2>/dev/null || true)
fi
if [[ -z "$wp" || "$wp" == "null" ]]; then
  for c in \
    "${HOME}/.config/hypr/current_wallpaper.jpg" \
    "${HOME}/Pictures/wallpapers"/* \
    "${HOME}/Imagens/wallpapers"/*; do
    [[ -f "$c" ]] && { wp=$c; break; }
  done
fi

if [[ -n "$wp" && -f "$wp" ]] && command -v dms >/dev/null; then
  dms ipc call wallpaper set "$wp" >/dev/null 2>&1 || true
  sleep 0.8
fi

if [[ ! -f "$COLORS" ]]; then
  echo "sync-niri-colors: missing $COLORS (DMS ainda não gerou)" >&2
  exit 1
fi

echo "=== $COLORS ==="
rg -n 'active-color|inactive-color' "$COLORS" || true

niri validate -c "${HOME}/.config/niri/config.kdl"
echo "niri ok — bordas usam dms/colors.kdl (live-reload)"

# Reaplica GTK4/Qt/flatpak a partir do dank-colors novo
if [[ -x "${HOME}/.config/scripts/unify-desktop-theme.sh" ]]; then
  "${HOME}/.config/scripts/unify-desktop-theme.sh" || true
fi
