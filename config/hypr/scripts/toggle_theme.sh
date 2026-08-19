#!/bin/bash

# Script para alternar o tema do sistema em tempo real - Tema Lavender Dream e Catppuccin Macchiato

THEME_FILE="$HOME/.config/active_theme"
CURRENT_THEME="lavender"

if [ -f "$THEME_FILE" ]; then
    CURRENT_THEME=$(cat "$THEME_FILE")
fi

if [ "$CURRENT_THEME" = "lavender" ]; then
    NEW_THEME="macchiato"
else
    NEW_THEME="lavender"
fi

echo "Alternando tema de $CURRENT_THEME para $NEW_THEME..."

# 1. Copia as cores do Hyprland
cp "$HOME/.config/hypr/themes/${NEW_THEME}_colors.conf" "$HOME/.config/hypr/theme_colors.conf"

# 2. (Removido) Geração de cores do Eww
# O Eww foi removido do seu setup; manter esse passo quebra o script quando
# eww removido do stack — configs antigas não existem mais.

# 3. Copia as cores do Foot
cp "$HOME/.config/foot/themes/${NEW_THEME}_colors.ini" "$HOME/.config/foot/colors.ini"

# 4. Salva o tema atual
echo "$NEW_THEME" > "$THEME_FILE"

# 5. Atualiza o tema GTK das janelas
if [ "$NEW_THEME" = "lavender" ]; then
    GTK_THEME="catppuccin-macchiato-lavender-standard+default"
else
    GTK_THEME="catppuccin-macchiato-mauve-standard+default"
fi
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null

# 6. Atualiza a paleta do Starship Prompt
if [ -f "$HOME/.config/starship.toml" ]; then
    if [ "$NEW_THEME" = "lavender" ]; then
        sed -i "s/palette = '.*'/palette = 'lavender'/g" "$HOME/.config/starship.toml"
    else
        sed -i "s/palette = '.*'/palette = 'catppuccin'/g" "$HOME/.config/starship.toml"
    fi
fi

# 7. Recarrega as configurações dos programas em execução
hyprctl reload

# 8. Atualiza o wallpaper em background para combinar com as cores do novo tema
~/.config/hypr/mudar_fundo.sh &

# Envia notificação visual
notify-send "Tema Alterado" "Desktop atualizado para: ${NEW_THEME} 🚀"
