#!/usr/bin/env bash
# Gera PNGs de zapfast/spotifast para a tray do DMS (SVG-only quebra no Quickshell).
set -euo pipefail
SIZES=(16 22 24 32 48 64 128)
for app in zapfast spotifast; do
  svg="/usr/share/icons/hicolor/scalable/apps/${app}.svg"
  [[ -f "$svg" ]] || continue
  for s in "${SIZES[@]}"; do
    dest="$HOME/.local/share/icons/hicolor/${s}x${s}/apps"
    mkdir -p "$dest"
    if [[ ! -f "$dest/${app}.png" ]] || [[ "$svg" -nt "$dest/${app}.png" ]]; then
      if command -v rsvg-convert >/dev/null; then
        rsvg-convert -w "$s" -h "$s" "$svg" -o "$dest/${app}.png"
      elif command -v magick >/dev/null; then
        magick -background none "$svg" -resize "${s}x${s}" "$dest/${app}.png"
      fi
    fi
  done
  mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
  cp -f "$svg" "$HOME/.local/share/icons/hicolor/scalable/apps/${app}.svg"
done
gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
