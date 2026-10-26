#!/usr/bin/env bash
# Padroniza aparência: GTK3/4 + libadwaita, Qt5/6, gsettings, flatpak, portais.
# Rode após trocar wallpaper/tema DMS, ou pelo menu Barista.
set -euo pipefail

GTK_THEME="${BARISTA_GTK_THEME:-adw-gtk3-dark}"
ICON_THEME="${BARISTA_ICON_THEME:-}"
CURSOR_THEME="${BARISTA_CURSOR_THEME:-macOS-hypr}"
CURSOR_SIZE="${BARISTA_CURSOR_SIZE:-32}"
FONT_NAME="${BARISTA_FONT_NAME:-ABC Areal 11}"
QT_COLOR_SCHEME="${BARISTA_QT_COLORS:-$HOME/.local/share/color-schemes/DankMatugenDark.colors}"

toast() {
  local m="$1"
  if command -v dms >/dev/null 2>&1; then
    dms ipc call toast info "$m" >/dev/null 2>&1 || notify-send "Tema" "$m"
  else
    notify-send "Tema" "$m" 2>/dev/null || echo "$m"
  fi
}

# Ícones: arg > gsettings > gtk ini > macOS
if [[ -z "$ICON_THEME" ]]; then
  ICON_THEME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || true)
fi
if [[ -z "$ICON_THEME" || "$ICON_THEME" == "''" ]]; then
  ICON_THEME=$(rg -o 'gtk-icon-theme-name=\K.*' "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || echo macOS)
fi
ICON_THEME="${ICON_THEME:-macOS}"

# ——— gsettings (apps GNOME/libadwaita leem isso) ———
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
gsettings set org.gnome.desktop.interface font-name "$FONT_NAME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true 2>/dev/null || true

# ——— GTK 3/4 settings.ini ———
write_gtk_ini() {
  local ini="$1"
  mkdir -p "$(dirname "$ini")"
  cat >"$ini" <<EOF
[Settings]
gtk-theme-name=${GTK_THEME}
gtk-icon-theme-name=${ICON_THEME}
gtk-font-name=${FONT_NAME}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=${CURSOR_SIZE}
gtk-application-prefer-dark-theme=1
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
}
write_gtk_ini "$HOME/.config/gtk-3.0/settings.ini"
write_gtk_ini "$HOME/.config/gtk-4.0/settings.ini"

# ——— GTK4 libadwaita :root a partir do dank-colors (evita tema claro fantasma) ———
python3 <<'PY'
import re
from pathlib import Path

home = Path.home()
dank = home / ".config/gtk-4.0/dank-colors.css"
# fallback gtk-3
if not dank.exists():
    dank = home / ".config/gtk-3.0/dank-colors.css"
defs = {}
if dank.exists():
    defs = dict(re.findall(r"@define-color\s+(\w+)\s+(#[0-9A-Fa-f]+)", dank.read_text()))

def c(name, fallback):
    return defs.get(name, fallback)

# defaults dark if matugen missing
win_bg = c("window_bg_color", "#101418")
win_fg = c("window_fg_color", "#c2c4ca")
view_bg = c("view_bg_color", win_bg)
view_fg = c("view_fg_color", win_fg)
hdr_bg = c("headerbar_bg_color", win_bg)
hdr_fg = c("headerbar_fg_color", win_fg)
side_bg = c("sidebar_bg_color", "#1d2024")
side_fg = c("sidebar_fg_color", win_fg)
sec_bg = c("secondary_sidebar_bg_color", win_bg)
sec_fg = c("secondary_sidebar_fg_color", win_fg)
pop_bg = c("popover_bg_color", side_bg)
pop_fg = c("popover_fg_color", win_fg)
dlg_bg = c("dialog_bg_color", win_bg)
dlg_fg = c("dialog_fg_color", win_fg)
card_bg = c("card_bg_color", side_bg)
card_fg = c("card_fg_color", win_fg)
acc_bg = c("accent_bg_color", "#74a1d0")
acc_fg = c("accent_fg_color", "#001e35")
err_bg = c("error_bg_color", "#ff7063")
err_fg = c("error_fg_color", "#3a0001")

out = home / ".config/gtk-4.0/gtk.css"
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(f"""@import url(\"dank-colors.css\");
/*
 * GTK4/libadwaita — gerado por unify-desktop-theme.sh
 * :root espelha dank-colors.css (matugen/DMS). Não editar à mão.
 */
:root {{
    --accent-bg-color: {acc_bg};
    --accent-fg-color: {acc_fg};
    --accent-color: {acc_bg};

    --destructive-bg-color: {err_bg};
    --destructive-fg-color: {err_fg};
    --error-bg-color: {err_bg};
    --error-fg-color: {err_fg};

    --window-bg-color: {win_bg};
    --window-fg-color: {win_fg};
    --view-bg-color: {view_bg};
    --view-fg-color: {view_fg};

    --headerbar-bg-color: {hdr_bg};
    --headerbar-fg-color: {hdr_fg};
    --headerbar-backdrop-color: {hdr_bg};
    --headerbar-border-color: transparent;
    --headerbar-shade-color: transparent;
    --headerbar-darker-shade-color: transparent;

    --sidebar-bg-color: {side_bg};
    --sidebar-fg-color: {side_fg};
    --sidebar-backdrop-color: {side_bg};
    --sidebar-border-color: transparent;
    --sidebar-shade-color: rgba(0, 0, 0, 0.35);

    --secondary-sidebar-bg-color: {sec_bg};
    --secondary-sidebar-fg-color: {sec_fg};
    --secondary-sidebar-backdrop-color: {sec_bg};
    --secondary-sidebar-border-color: transparent;
    --secondary-sidebar-shade-color: rgba(0, 0, 0, 0.35);

    --popover-bg-color: {pop_bg};
    --popover-fg-color: {pop_fg};
    --popover-shade-color: rgba(0, 0, 0, 0.35);

    --dialog-bg-color: {dlg_bg};
    --dialog-fg-color: {dlg_fg};

    --card-bg-color: {card_bg};
    --card-fg-color: {card_fg};
    --card-shade-color: rgba(0, 0, 0, 0.25);

    --thumbnail-bg-color: {side_bg};
    --thumbnail-fg-color: {side_fg};

    --shade-color: rgba(0, 0, 0, 0.35);
    --scrollbar-outline-color: rgba(255, 255, 255, 0.08);
}}

tooltip * {{
    background-color: transparent;
}}
tooltip.background {{
    background-color: {pop_bg};
    color: {pop_fg};
}}
""")
print(f"gtk4 :root ← {dank.name if dank.exists() else 'defaults'} ({win_bg})")
PY

# GTK3: garantir import do dank-colors
if [[ -f "$HOME/.config/gtk-3.0/dank-colors.css" ]]; then
  if [[ ! -f "$HOME/.config/gtk-3.0/gtk.css" ]] || ! rg -q 'dank-colors' "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null; then
    printf '@import url("dank-colors.css");\n' >"$HOME/.config/gtk-3.0/gtk.css"
  fi
fi

# ——— Qt5/Qt6 → mesma paleta escura do DMS ———
for conf in "$HOME/.config/qt5ct/qt5ct.conf" "$HOME/.config/qt6ct/qt6ct.conf"; do
  mkdir -p "$(dirname "$conf")"
  if [[ ! -f "$conf" ]]; then
    cat >"$conf" <<EOF
[Appearance]
color_scheme_path=${QT_COLOR_SCHEME}
custom_palette=true
icon_theme=${ICON_THEME}
style=Darkly

[Fonts]
general="${FONT_NAME%,*},11,-1,5,400,0,0,0,0,0,Regular"
fixed="ABC Areal Mono,11,-1,5,400,0,0,0,0,0,Regular"
EOF
  else
    if rg -q '^color_scheme_path=' "$conf"; then
      sed -i "s|^color_scheme_path=.*|color_scheme_path=${QT_COLOR_SCHEME}|" "$conf"
    else
      printf '\n[Appearance]\ncolor_scheme_path=%s\n' "$QT_COLOR_SCHEME" >>"$conf"
    fi
    if rg -q '^icon_theme=' "$conf"; then
      sed -i "s|^icon_theme=.*|icon_theme=${ICON_THEME}|" "$conf"
    else
      sed -i "/^\[Appearance\]/a icon_theme=${ICON_THEME}" "$conf" 2>/dev/null || \
        printf 'icon_theme=%s\n' "$ICON_THEME" >>"$conf"
    fi
    if rg -q '^custom_palette=' "$conf"; then
      sed -i 's|^custom_palette=.*|custom_palette=true|' "$conf"
    fi
  fi
done

# ——— environment.d (novas sessões) ———
mkdir -p "$HOME/.config/environment.d"
cat >"$HOME/.config/environment.d/20-barista-theme.conf" <<EOF
GTK_THEME=${GTK_THEME}
GTK_ICON_THEME=${ICON_THEME}
XCURSOR_THEME=${CURSOR_THEME}
XCURSOR_SIZE=${CURSOR_SIZE}
QT_QPA_PLATFORMTHEME=qt6ct
EOF

# niri já tem QT/XCURSOR — reforça GTK no config se possível via env block é manual;
# session atual:
export GTK_THEME ICON_THEME
export GTK_THEME="$GTK_THEME"

# ——— xdg-desktop-portal: menus/file pickers GTK (não misturar KDE) ———
mkdir -p "$HOME/.config/xdg-desktop-portal"
cat >"$HOME/.config/xdg-desktop-portal/portals.conf" <<'EOF'
[preferred]
default=gtk;gnome;
org.freedesktop.impl.portal.Secret=gnome-keyring;
org.freedesktop.impl.portal.Settings=gnome;gtk;
org.freedesktop.impl.portal.FileChooser=gtk;
org.freedesktop.impl.portal.AppChooser=gtk;
org.freedesktop.impl.portal.Print=gtk;
EOF

# restart portals if running (best-effort)
systemctl --user restart xdg-desktop-portal.service xdg-desktop-portal-gtk.service 2>/dev/null || true

# ——— Flatpak: mesma cara do host ———
if command -v flatpak >/dev/null 2>&1; then
  flatpak override --user \
    --env=GTK_THEME="$GTK_THEME" \
    --env=ICON_THEME="$ICON_THEME" \
    --env=XCURSOR_THEME="$CURSOR_THEME" \
    --env=XCURSOR_SIZE="$CURSOR_SIZE" \
    --filesystem=xdg-config/gtk-3.0:ro \
    --filesystem=xdg-config/gtk-4.0:ro \
    --filesystem=xdg-data/themes:ro \
    --filesystem=/usr/share/themes:ro \
    --filesystem=/usr/share/icons:ro \
    --filesystem=xdg-data/icons:ro \
    >/dev/null 2>&1 || true
fi

# ——— DMS settings iconTheme ———
python3 - "$ICON_THEME" <<'PY'
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

toast "Tema unificado: ${GTK_THEME} · ${ICON_THEME} · Qt DankMatugenDark (reabra apps)"
echo "OK gtk=${GTK_THEME} icons=${ICON_THEME} cursor=${CURSOR_THEME} qt=$(basename "$QT_COLOR_SCHEME")"
