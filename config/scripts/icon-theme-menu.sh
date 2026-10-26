#!/usr/bin/env bash
# Escolhe tema de ícones (GTK + Qt + gsettings).
set -euo pipefail

PICKER="${HOME}/.config/scripts/picker.sh"

toast() {
  local m="$1"
  dms ipc call toast info "$m" >/dev/null 2>&1 || notify-send "Ícones" "$m"
}

# Temas com index.theme em /usr/share/icons e ~/.local/share/icons
mapfile -t THEMES < <(
  find /usr/share/icons "$HOME/.local/share/icons" -maxdepth 2 -name index.theme 2>/dev/null \
    | while read -r f; do basename "$(dirname "$f")"; done \
    | rg -v '^(default|hicolor|locolor|.*[Cc]ursor.*|breeze_cursors)$' \
    | sort -u
)

CURRENT=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || echo "?")
CHOICE=$(printf '%s\n' "Atual: ${CURRENT}" "${THEMES[@]}" | "$PICKER" -p "Ícones")
[[ -z "${CHOICE:-}" || "$CHOICE" == Atual:* ]] && exit 0

gsettings set org.gnome.desktop.interface icon-theme "$CHOICE" 2>/dev/null || true

# GTK
for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
  [[ -f "$ini" ]] || continue
  if rg -q '^gtk-icon-theme-name=' "$ini"; then
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=${CHOICE}/" "$ini"
  else
    printf '\ngtk-icon-theme-name=%s\n' "$CHOICE" >>"$ini"
  fi
done

# Qt
for conf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
  [[ -f "$conf" ]] || continue
  if rg -q '^icon_theme=' "$conf"; then
    sed -i "s/^icon_theme=.*/icon_theme=${CHOICE}/" "$conf"
  else
    printf '\n[Appearance]\nicon_theme=%s\n' "$CHOICE" >>"$conf"
  fi
done

# DMS settings (se a chave existir / for aceita)
python3 - "$CHOICE" <<'PY'
import json, sys
from pathlib import Path
theme = sys.argv[1]
for p in [
    Path.home()/".config/DankMaterialShell/settings.json",
    Path.home()/"dotfiles/config/DankMaterialShell/settings.json",
]:
    if not p.exists():
        continue
    d = json.loads(p.read_text())
    d["iconTheme"] = theme
    p.write_text(json.dumps(d, indent=2) + "\n")
PY

# Propaga ícone + re-sincroniza GTK/Qt/flatpak/portais
BARISTA_ICON_THEME="$CHOICE" "${HOME}/.config/scripts/unify-desktop-theme.sh" >/dev/null
toast "Ícones → $CHOICE (reabra apps p/ aplicar tudo)"
