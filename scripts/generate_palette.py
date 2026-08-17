import sys
import json
import colorsys
import os

if len(sys.argv) < 2:
    print("Uso: python3 generate_palette.py #RRGGBB")
    sys.exit(1)

hex_color = sys.argv[1].lstrip('#')
if len(hex_color) != 6:
    print("Por favor, forneça uma cor HEX válida (ex: #ff0000)")
    sys.exit(1)

r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
h, s, v = colorsys.rgb_to_hsv(r/255.0, g/255.0, b/255.0)

# Garantir que a cor base tenha saturação e valor suficientes para gerar uma paleta visível
s = max(0.4, s)
v = max(0.5, v)

def hsv2hex(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h, s, v)
    return "#{:02x}{:02x}{:02x}".format(int(r*255), int(g*255), int(b*255))

theme = {
    "special": {
        "background": hsv2hex(h, s, 0.08),
        "foreground": hsv2hex(h, 0.1, 0.95),
        "cursor": hsv2hex(h, s, 0.8)
    },
    "colors": {
        "color0": hsv2hex(h, s, 0.08),
        "color1": hsv2hex(h, s, 0.8),
        "color2": hsv2hex((h+0.1)%1.0, s, 0.8),
        "color3": hsv2hex((h+0.2)%1.0, s, 0.8),
        "color4": hsv2hex(h, s, 0.6),
        "color5": hsv2hex((h+0.05)%1.0, s, 0.7),
        "color6": hsv2hex((h-0.1)%1.0, s, 0.8),
        "color7": hsv2hex(h, 0.1, 0.8),
        "color8": hsv2hex(h, s, 0.3),
        "color9": hsv2hex(h, s, 0.9),
        "color10": hsv2hex((h+0.1)%1.0, s, 0.9),
        "color11": hsv2hex((h+0.2)%1.0, s, 0.9),
        "color12": hsv2hex(h, s, 0.7),
        "color13": hsv2hex((h+0.05)%1.0, s, 0.8),
        "color14": hsv2hex((h-0.1)%1.0, s, 0.9),
        "color15": hsv2hex(h, 0.1, 0.95)
    }
}

out_dir = os.path.expanduser("~/.cache/wal")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "custom_theme.json")

with open(out_path, "w") as f:
    json.dump(theme, f)

print(out_path)
