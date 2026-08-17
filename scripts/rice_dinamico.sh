#!/bin/bash
# Gerenciador de Tema Dinâmico via Pywal

WALLPAPER="$1"

if [ -z "$WALLPAPER" ]; then
    echo "Uso: $0 /caminho/para/imagem.jpg"
    exit 1
fi

if ! command -v wal >/dev/null 2>&1; then
    echo "Erro: O 'pywal' não está instalado."
    echo "Instale usando: sudo pacman -S python-pywal"
    exit 1
fi

echo "🎨 Gerando tema a partir de: $WALLPAPER"
wal -q -n -i "$WALLPAPER" --saturate 0.6

# Pywal gera variáveis em ~/.cache/wal/colors.sh
source "$HOME/.cache/wal/colors.sh"

# 1. Atualizando o arquivo de cores do Hyprland
HYPR_THEME="$HOME/.config/hypr/theme_colors.conf"
cat <<EOF > "$HYPR_THEME"
\$active_border = rgba(${color4:1}ff) rgba(${color5:1}ff) 45deg
\$inactive_border = rgba(${color0:1}aa)
\$shadow_color = rgba(${color0:1}99)
EOF
hyprctl reload >/dev/null 2>&1

# 2. Atualizando Hyprlock
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

# 3. Waybar: O pywal já gera um arquivo de cores que podemos usar, mas vamos garantir o nosso colors.css
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

# 4. Foot: O Foot tem suporte nativo para ler os arquivos do pywal (já criados em ~/.cache/wal/colors.ini)
# Vamos apenas apontar o colors.ini do foot para lá
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

# Notifica
if command -v notify-send >/dev/null 2>&1; then
    notify-send "Rice Dinâmico Aplicado" "Tema extraído de: $(basename "$WALLPAPER")"
fi
echo "✅ Tema dinâmico aplicado com sucesso!"

# 5. Atualizando cores do Rofi
ROFI_COLORS="$HOME/.config/rofi/colors.rasi"
cat <<ROFIOF > "$ROFI_COLORS"
* {
    bg: #${color0:1}F2;
    bg-alt: #${color4:1}26;
    accent: ${color4};
    fg: ${color7};
    fg-alt: ${color5};
}
ROFIOF
