#!/usr/bin/env bash
# Pós-apply: permissões, serviços user, fontes, reload leve.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[post-apply] chmod em scripts..."
find "$HOME/.config/scripts" -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
chmod +x "$ROOT/local-bin/"* 2>/dev/null || true
chmod +x "$ROOT/hooks/"*.sh 2>/dev/null || true
chmod +x "$ROOT/migrate-stack.sh" 2>/dev/null || true

echo "[post-apply] systemd user..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload 2>/dev/null || true
  for unit in dms-alacritty-sync.path dms-alacritty-sync.service; do
    if [[ -f "$HOME/.config/systemd/user/$unit" ]]; then
      systemctl --user enable "$unit" 2>/dev/null || true
    fi
  done
  # DMS via systemd (niri não faz spawn — evita double-start)
  systemctl --user enable dms.service 2>/dev/null || true
  # disable old foot sync if present
  systemctl --user disable --now dms-foot-sync.path dms-foot-sync.service 2>/dev/null || true
  systemctl --user restart dms-alacritty-sync.path 2>/dev/null || true
fi

echo "[post-apply] tmux plugin..."
if [[ -x "$ROOT/hooks/setup-tmux.sh" ]]; then
  "$ROOT/hooks/setup-tmux.sh" 2>/dev/null || true
fi

echo "[post-apply] sync alacritty <- DMS (se existir)..."
if [[ -x "$HOME/.config/scripts/sync-alacritty-theme-dms.sh" ]]; then
  "$HOME/.config/scripts/sync-alacritty-theme-dms.sh" 2>/dev/null || true
fi

echo "[post-apply] tray icons zapfast/spotifast..."
if [[ -x "$ROOT/hooks/sync-tray-icons.sh" ]]; then
  "$ROOT/hooks/sync-tray-icons.sh" 2>/dev/null || true
fi

echo "[post-apply] Thunar bookmarks..."
if [[ -f "$ROOT/config/gtk-3.0/bookmarks.in" ]]; then
  mkdir -p "$HOME/.config/gtk-3.0"
  # shellcheck disable=SC2016
  envsubst <"$ROOT/config/gtk-3.0/bookmarks.in" >"$HOME/.config/gtk-3.0/bookmarks"
fi

echo "[post-apply] fc-cache..."
fc-cache -f >/dev/null 2>&1 || true

# Cursor macOS (xcursor) — niri usa XCursor; hyprcursor opcional
if [[ -d /usr/share/icons/macOS/cursors ]]; then
  echo "[post-apply] cursor macOS (xcursor)..."
  local_theme="$HOME/.local/share/icons/macOS-hypr"
  mkdir -p "$local_theme"
  cat > "$local_theme/index.theme" << 'EOF'
[Icon Theme]
Name=macOS-hypr
Comment=Apple macOS cursors
Inherits=hicolor
Example=left_ptr
EOF
  ln -sfn /usr/share/icons/macOS/cursors "$local_theme/cursors"
  if [[ -d /usr/share/icons/macOS-hypr/hyprcursors ]]; then
    cp -f /usr/share/icons/macOS-hypr/manifest.hl "$local_theme/manifest.hl" 2>/dev/null || true
    ln -sfn /usr/share/icons/macOS-hypr/hyprcursors "$local_theme/hyprcursors"
  fi
fi

if [[ "${XDG_CURRENT_DESKTOP:-}" == *niri* ]] || [[ "${XDG_SESSION_DESKTOP:-}" == *niri* ]]; then
  echo "[post-apply] niri validate..."
  niri validate 2>/dev/null || true
  if command -v dms >/dev/null 2>&1 && [[ -f "$HOME/.config/hypr/current_wallpaper.jpg" ]]; then
    dms ipc call wallpaper set "$HOME/.config/hypr/current_wallpaper.jpg" 2>/dev/null || true
  fi
fi

echo "[post-apply] ok"
