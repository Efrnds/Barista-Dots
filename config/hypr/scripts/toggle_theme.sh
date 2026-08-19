#!/bin/bash
# Alterna tema local lavender ↔ macchiato (legado Catppuccin).
# Tema principal do desktop: DMS dynamic/matugen.

set -euo pipefail

THEME_FILE="$HOME/.config/active_theme"
CURRENT_THEME="lavender"

[[ -f "$THEME_FILE" ]] && CURRENT_THEME="$(cat "$THEME_FILE")"

if [[ "$CURRENT_THEME" == "lavender" ]]; then
  NEW_THEME="macchiato"
else
  NEW_THEME="lavender"
fi

cp "$HOME/.config/hypr/themes/${NEW_THEME}_colors.conf" "$HOME/.config/hypr/theme_colors.conf"
cp "$HOME/.config/foot/themes/${NEW_THEME}_colors.ini" "$HOME/.config/foot/colors.ini"
echo "$NEW_THEME" > "$THEME_FILE"

if [[ "$NEW_THEME" == "lavender" ]]; then
  GTK_THEME="catppuccin-macchiato-lavender-standard+default"
  STAR_PALETTE="lavender"
else
  GTK_THEME="catppuccin-macchiato-mauve-standard+default"
  STAR_PALETTE="catppuccin"
fi

gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true

if [[ -f "$HOME/.config/starship.toml" ]]; then
  sed -i "s/palette = '.*'/palette = '${STAR_PALETTE}'/g" "$HOME/.config/starship.toml"
fi

hyprctl reload
"$HOME/.config/hypr/mudar_fundo.sh" &
notify-send "Tema Alterado" "Desktop atualizado para: ${NEW_THEME}"
