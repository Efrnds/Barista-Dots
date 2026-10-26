#!/usr/bin/env bash
# Escala de texto global: DMS bar + GTK + Alacritty
set -euo pipefail

PICKER="${HOME}/.config/scripts/picker.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista"
mkdir -p "$STATE"
CONF="${STATE}/text-scale"

current=$(cat "$CONF" 2>/dev/null || echo "1.0")

choice=$(printf '%s\n' \
  "0.85 (menor)" \
  "1.0 (padrão) ← atual se não souber" \
  "1.1" \
  "1.15" \
  "1.25" \
  "1.35" \
  "1.5 (maior)" \
  "Atual: ${current}" \
  | "$PICKER" -p "Escala de texto")

[[ -z "${choice:-}" || "$choice" == Atual:* ]] && exit 0
scale=$(echo "$choice" | awk '{print $1}')
[[ "$scale" =~ ^[0-9.]+$ ]] || exit 1
echo "$scale" > "$CONF"

# GTK / GNOME
gsettings set org.gnome.desktop.interface text-scaling-factor "$scale" 2>/dev/null || true

# DMS bar fontScale (todas as bars)
python3 - "$scale" <<'PY'
import json, sys
from pathlib import Path
scale = float(sys.argv[1])
paths = [
    Path.home() / ".config/DankMaterialShell/settings.json",
]
# Prefer symlink target (dotfiles)
for p in paths:
    if not p.exists():
        continue
    data = json.loads(p.read_text())
    for bar in data.get("barConfigs", []):
        bar["fontScale"] = scale
        bar["iconScale"] = scale
    p.write_text(json.dumps(data, indent=2) + "\n")
    print("updated", p)
PY

# Alacritty: base 11 * scale
base=11
size=$(python3 -c "print(round($base * $scale, 1))")
for ALA in "${HOME}/.config/alacritty/alacritty.toml" \
           "${HOME}/dotfiles/templates/alacritty.toml.in"; do
  [[ -f "$ALA" ]] || continue
  sed -i -E "s/^(size = ).*/\\1${size}/" "$ALA"
done

# Também atualiza template renderizado no próximo apply — patch runtime ok
if command -v dms >/dev/null; then
  dms ipc call settings set "barConfigs" "$(python3 -c "import json;print(json.load(open('$HOME/.config/DankMaterialShell/settings.json'))['barConfigs'])")" >/dev/null 2>&1 || true
  # Soft hint: toast; user may need reopen settings or restart dms for bar
  dms ipc call toast info "Escala de texto: ${scale} (Alacritty ${size}pt)" >/dev/null 2>&1 || true
fi
notify-send "Escala" "${scale}× — se a bar não mudar, Super+Shift+P → reaplique ou reinicie o DMS"
