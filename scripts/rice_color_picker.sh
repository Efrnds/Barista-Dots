#!/bin/bash
# Color picker and theme generator

if ! command -v hyprpicker >/dev/null 2>&1; then
    echo "Erro: hyprpicker não instalado."
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Erro" "Instale o hyprpicker: sudo pacman -S hyprpicker"
    fi
    exit 1
fi

if ! command -v wal >/dev/null 2>&1; then
    echo "Erro: pywal não instalado."
    exit 1
fi

# Pega a cor
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Color Picker" "Clique em qualquer lugar da tela para copiar a cor."
fi
COLOR=$(hyprpicker -a -f hex)

if [ -z "$COLOR" ]; then
    echo "Nenhuma cor selecionada."
    exit 1
fi

echo "Cor escolhida: $COLOR"

# Gera o JSON da paleta
JSON_PATH=$(python3 "$HOME/dotfiles/scripts/generate_palette.py" "$COLOR")

# Roda o Pywal com o arquivo customizado
wal -q -n --theme "$JSON_PATH"

# Importa as cores geradas
source "$HOME/.cache/wal/colors.sh"

# Aplica as cores do mesmo jeito que o rice_dinamico.sh
HYPR_THEME="$HOME/.config/hypr/theme_colors.conf"
cat <<EOF > "$HYPR_THEME"
\$active_border = rgba(${color4:1}ff) rgba(${color5:1}ff) 45deg
\$inactive_border = rgba(${color0:1}aa)
\$shadow_color = rgba(${color0:1}99)
EOF
hyprctl reload >/dev/null 2>&1

HYPRLOCK_THEME="$HOME/.config/hypr/theme_hyprlock.conf"
cat <<EOF > "$HYPRLOCK_THEME"
\$outer_color = rgba(${color4:1}ff)
\$inner_color = rgba(${color0:1}dd)
\$font_color = rgb(${color7:1})
\$check_color = rgba(${color3:1}ff)
\$fail_color = rgba(${color1:1}ff)
\$capslock_color = rgba(${color5:1}ff)
\$border_color = rgba(${color4:1}cc)
\$label_color = rgba(${color4:1}dd)
\$date_color = rgba(${color5:1}ff)
\$greet_color = rgba(${color7:1}bb)
EOF

WAYBAR_COLORS="$HOME/.config/waybar/colors.css"
cat <<EOF > "$WAYBAR_COLORS"
@define-color bg_color rgba(${color0:1}, 0.85);
@define-color border_color rgba(${color4:1}, 0.25);
@define-color active_color $color4;
@define-color text_color $color7;
@define-color accent_color $color5;
@define-color pill_bg rgba(${color4:1}, 0.12);
EOF
pkill -USR2 waybar || pkill waybar ; waybar &

ROFI_COLORS="$HOME/.config/rofi/colors.rasi"
cat <<EOF > "$ROFI_COLORS"
* {
    bg: #${color0:1}F2;
    bg-alt: #${color4:1}26;
    accent: ${color4};
    fg: ${color7};
    fg-alt: ${color5};
}
EOF

FOOT_COLORS="$HOME/.config/foot/colors.ini"
cat <<EOF > "$FOOT_COLORS"
[colors]
alpha=0.9
background=${color0:1}
foreground=${color7:1}
regular0=${color0:1}
regular1=${color1:1}
regular2=${color2:1}
regular3=${color3:1}
regular4=${color4:1}
regular5=${color5:1}
regular6=${color6:1}
regular7=${color7:1}
EOF
killall -USR1 foot || true

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Tema Dinâmico" "Tema atualizado para a cor $COLOR!"
fi
touch "$HOME/.config/hypr/theme_locked"
