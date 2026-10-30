#!/usr/bin/env bash
# Instala Plymouth + tema barista (logo + barrinha) e ativa no boot.
set -euo pipefail

THEME_SRC="$(cd "$(dirname "$0")" && pwd)/barista"
THEME_DST="/usr/share/plymouth/themes/barista"

if [[ $EUID -ne 0 ]]; then
  exec sudo -A "$0" "$@"
fi

echo "==> pacotes"
pacman -S --needed --noconfirm plymouth

echo "==> tema barista"
install -d "$THEME_DST"
install -m644 "$THEME_SRC"/* "$THEME_DST/"
plymouth-set-default-theme -R barista

echo "==> mkinitcpio (HOOKS)"
conf=/etc/mkinitcpio.conf
python3 - <<'PY'
from pathlib import Path
p = Path("/etc/mkinitcpio.conf")
lines = p.read_text().splitlines()
out = []
for line in lines:
    if line.startswith("HOOKS=") and "plymouth" not in line:
        if "systemd" in line:
            line = line.replace("systemd", "systemd plymouth", 1)
        elif "udev" in line:
            line = line.replace("udev", "udev plymouth", 1)
        else:
            line = line.replace("HOOKS=(", "HOOKS=(plymouth ", 1)
    out.append(line)
p.write_text("\n".join(out) + "\n")
PY
grep '^HOOKS=' "$conf"

echo "==> GRUB: quiet splash + menu curto"
grub=/etc/default/grub
# garanta splash (e quiet)
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub"; then
  # remove splash duplicado, reescreve default
  cur=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub" | sed -E 's/^GRUB_CMDLINE_LINUX_DEFAULT=//; s/^"//; s/"$//')
  cur=$(echo "$cur" | sed -E 's/\bsplash\b//g; s/\s+/ /g; s/^\s+|\s+$//g')
  # quiet loglevel já existem no teu setup
  echo "$cur" | grep -qw quiet || cur="quiet $cur"
  echo "$cur" | grep -qw splash || cur="$cur splash"
  echo "$cur" | grep -qw loglevel=3 || cur="loglevel=3 $cur"
  sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$cur\"|" "$grub"
fi
# boot mais clean: menu escondido, 2s (Shift mostra)
sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=2/' "$grub"
sed -i -E 's/^#?GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$grub" || true
grep -E '^GRUB_(TIMEOUT|CMDLINE_LINUX_DEFAULT|TIMEOUT_STYLE)=' "$grub"

# Garante initramfs tradicional (GRUB) além do UKI
preset=/etc/mkinitcpio.d/linux.preset
if [[ -f "$preset" ]] && ! grep -q '^default_image=' "$preset"; then
  echo 'default_image="/boot/initramfs-linux.img"' >> "$preset"
fi

echo "==> rebuild initramfs + grub"
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

echo "==> ok. No próximo boot: logo Tux + barrinha (sem parede de texto)."
echo "    (Segura Shift no boot se quiser o menu do GRUB.)"
