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
  # drop-ins (ex.: DMS_SHELL_DIR para patch de avatar)
  if [[ -d "$ROOT/systemd/user/dms.service.d" ]]; then
    mkdir -p "$HOME/.config/systemd/user/dms.service.d"
    for f in "$ROOT/systemd/user/dms.service.d/"*; do
      [[ -f "$f" ]] || continue
      ln -sfn "$f" "$HOME/.config/systemd/user/dms.service.d/$(basename "$f")"
    done
  fi
  systemctl --user daemon-reload 2>/dev/null || true
  for unit in dms-alacritty-sync.path dms-alacritty-sync.service avatar-sync.path; do
    if [[ -f "$HOME/.config/systemd/user/$unit" ]]; then
      systemctl --user enable --now "$unit" 2>/dev/null || true
    fi
  done
  # DMS via systemd (niri não faz spawn — evita double-start)
  systemctl --user enable dms.service 2>/dev/null || true
  # disable old foot sync if present
  systemctl --user disable --now dms-foot-sync.path dms-foot-sync.service 2>/dev/null || true
  systemctl --user restart dms-alacritty-sync.path 2>/dev/null || true
fi

echo "[post-apply] DMS plugins (symlinks)..."
mkdir -p "$HOME/.config/DankMaterialShell/plugins"
if [[ -d "$ROOT/dms-plugins" ]]; then
  for plugin in "$ROOT/dms-plugins/"*; do
    [[ -d "$plugin" ]] || continue
    ln -sfn "$plugin" "$HOME/.config/DankMaterialShell/plugins/$(basename "$plugin")"
  done
fi

echo "[post-apply] avatar patch (AccountsService 1MiB)..."
if [[ -x "$HOME/.config/scripts/patch-dms-avatar.sh" ]]; then
  # Bootstrap UI copy if missing (needed for DMS_SHELL_DIR)
  if [[ ! -f "$HOME/.local/share/dms-ui/shell.qml" ]]; then
    shopt -s nullglob
    lives=(/run/user/"$(id -u)"/danklinux-shell/*/)
    if [[ ${#lives[@]} -gt 0 && -f "${lives[0]}shell.qml" ]]; then
      rm -rf "$HOME/.local/share/dms-ui"
      mkdir -p "$HOME/.local/share/dms-ui"
      cp -a "${lives[0]}." "$HOME/.local/share/dms-ui/"
      chmod -R u+w "$HOME/.local/share/dms-ui" 2>/dev/null || true
    fi
    shopt -u nullglob
  fi
  "$HOME/.config/scripts/patch-dms-avatar.sh" 2>/dev/null || true
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

echo "[post-apply] Thunar bookmarks (respeita XDG user-dirs / idioma)..."
if [[ -f "$ROOT/config/gtk-3.0/bookmarks.in" ]]; then
  mkdir -p "$HOME/.config/gtk-3.0"
  # Carrega pastas traduzidas (Pictures vs Imagens, etc.)
  # shellcheck disable=SC1090
  [[ -f "$HOME/.config/user-dirs.dirs" ]] && . "$HOME/.config/user-dirs.dirs"
  export XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
  export XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
  export XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
  export XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
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
