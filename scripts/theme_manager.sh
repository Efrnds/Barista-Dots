#!/bin/bash
# Gerenciador de Temas
# Aplica cores ao sistema inteiro (waybar, foot, hyprland, hyprlock, ly)

THEME="$1"
VALID_THEMES=("lavender" "macchiato")

if [[ ! " ${VALID_THEMES[@]} " =~ " ${THEME} " ]]; then
    echo "Erro: Tema '$THEME' inválido. Temas disponíveis: ${VALID_THEMES[*]}"
    exit 1
fi

echo "Aplicando tema: $THEME..."

# 1. Waybar
WAYBAR_THEME="$HOME/.config/waybar/themes/${THEME}_colors.css"
if [ -f "$WAYBAR_THEME" ]; then
    cp -f "$WAYBAR_THEME" "$HOME/.config/waybar/colors.css"
    # Recarrega as cores do Waybar sem reiniciar o daemon completamente (se suportado) ou reinicia
    pkill -USR2 waybar || pkill waybar ; waybar &
fi

# 2. Foot
FOOT_THEME="$HOME/.config/foot/themes/${THEME}_colors.ini"
if [ -f "$FOOT_THEME" ]; then
    cp -f "$FOOT_THEME" "$HOME/.config/foot/colors.ini"
fi

# 3. Hyprland
HYPR_THEME="$HOME/.config/hypr/themes/${THEME}_colors.conf"
if [ -f "$HYPR_THEME" ]; then
    cp -f "$HYPR_THEME" "$HOME/.config/hypr/theme_colors.conf"
    hyprctl reload >/dev/null 2>&1
fi

# 4. Hyprlock (Tela de bloqueio)
HYPRLOCK_THEME="$HOME/.config/hypr/themes/${THEME}_hyprlock.conf"
if [ -f "$HYPRLOCK_THEME" ]; then
    cp -f "$HYPRLOCK_THEME" "$HOME/.config/hypr/theme_hyprlock.conf"
fi

# 5. Ly (Tela de login)
# Precisaria de permissão de root para alterar o /etc/ly/config.ini diretamente.
# Podemos usar um sed no /etc/ly/config.ini se for executado com sudo.
if [ "$EUID" -eq 0 ] && command -v ly >/dev/null; then
    if [ "$THEME" = "macchiato" ]; then
        sed -i 's/bg = .*/bg = 0x24273a/' /etc/ly/config.ini
    elif [ "$THEME" = "lavender" ]; then
        sed -i 's/bg = .*/bg = 0x424874/' /etc/ly/config.ini
    fi
fi

# Salva o tema atual
echo "$THEME" > "$HOME/.config/active_theme"

# Notifica o usuário
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Gerenciador de Tema" "Tema alterado para: $THEME"
fi

echo "Tema alterado para $THEME com sucesso!"
