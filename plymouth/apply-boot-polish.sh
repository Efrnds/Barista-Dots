#!/usr/bin/env bash
# Aplica: tema barista, zero texto GRUB, shutdown clean, fingerprint greeter.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
THEME_SRC="$ROOT/barista"

if [[ $EUID -ne 0 ]]; then
  exec sudo -A "$0" "$@"
fi

echo "==> tema Plymouth barista"
install -d /usr/share/plymouth/themes/barista
install -m644 "$THEME_SRC"/* /usr/share/plymouth/themes/barista/
plymouth-set-default-theme barista
# force in both configs
mkdir -p /etc/plymouth
cat >/etc/plymouth/plymouthd.conf <<'EOF'
[Daemon]
Theme=barista
ShowDelay=0
DeviceTimeout=8
EOF

echo "==> kernel cmdline quiet absoluto + splash"
grub=/etc/default/grub
# loglevel=0 + systemd mudo no boot/shutdown
desired='loglevel=0 quiet splash vt.global_cursor_default=0 systemd.show_status=false rd.udev.log_level=3'
sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$desired\"|" "$grub"
sed -i -E 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' "$grub"
sed -i -E 's/^#?GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' "$grub"
# mantém gfx
sed -i -E 's/^#?GRUB_GFXPAYLOAD_LINUX=.*/GRUB_GFXPAYLOAD_LINUX=keep/' "$grub"
grep -E '^GRUB_(TIMEOUT|CMDLINE_LINUX_DEFAULT|TIMEOUT_STYLE)=' "$grub"

echo "==> systemd ShowStatus=error (menos texto no shutdown)"
mkdir -p /etc/systemd/system.conf.d
cat >/etc/systemd/system.conf.d/barista-quiet.conf <<'EOF'
[Manager]
ShowStatus=error
LogLevel=err
EOF

echo "==> quiet-grub helper + pacman hook"
install -d /usr/local/lib/barista
install -m755 "$ROOT/99-barista-quiet-grub.cfg.sh" /usr/local/lib/barista/quiet-grub.sh
install -d /etc/pacman.d/hooks
install -m644 "$ROOT/zz-barista-grub-quiet.hook" /etc/pacman.d/hooks/zz-barista-grub-quiet.hook

echo "==> mkinitcpio HOOKS plymouth"
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
    out.append(line)
p.write_text("\n".join(out) + "\n")
print([l for l in out if l.startswith("HOOKS=")][0])
PY

# initramfs tradicional
preset=/etc/mkinitcpio.d/linux.preset
if [[ -f "$preset" ]] && ! grep -q '^default_image=' "$preset"; then
  echo 'default_image="/boot/initramfs-linux.img"' >> "$preset"
fi

echo "==> PAM greetd: digital OU senha (fprintd primeiro p/ UI ouvir)"
# Backup once
[[ -f /etc/pam.d/greetd.barista.bak ]] || cp -a /etc/pam.d/greetd /etc/pam.d/greetd.barista.bak
cat >/etc/pam.d/greetd <<'EOF'
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so

# Digital primeiro (greeter pode disparar fprintd com senha vazia);
# senha continua sufficient — um OU outro.
auth       sufficient   pam_fprintd.so
auth       sufficient   pam_unix.so try_first_pass nullok
auth       required     pam_deny.so

account    include      system-local-login
password   include      system-local-login
session    optional     pam_gnome_keyring.so auto_start
session    include      system-local-login
EOF

# greeter precisa falar com open-fprintd / device
usermod -aG input,video greeter 2>/dev/null || true

echo "==> rebuild initramfs + grub + silenciar echoes"
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
/usr/local/lib/barista/quiet-grub.sh

echo "==> dms-greeter: NÃO rode sync como root (quebra symlinks → /root)."
echo "    Como usuário: DMS_PRIVESC=sudo dms-greeter sync -y"

echo "==> verificação rápida"
plymouth-set-default-theme
rg -n "echo.*Carregando|quiet splash|loglevel" /boot/grub/grub.cfg | head -15
echo "PAM greetd:"; grep -E 'fprint|unix|deny' /etc/pam.d/greetd
echo "OK. Logo Lenovo = só via BIOS (Quiet Boot / Hide Boot Logo)."