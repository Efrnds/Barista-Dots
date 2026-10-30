#!/usr/bin/env bash
set -euo pipefail
[[ $EUID -eq 0 ]] || exec sudo -A "$0" "$@"

install -d /etc/systemd/system.conf.d /etc/sysctl.d
install -m644 /home/eduardo/dotfiles/systemd/system/barista-quiet.conf /etc/systemd/system.conf.d/barista-quiet.conf
install -m644 /home/eduardo/dotfiles/sysctl.d/20-barista-quiet.conf /etc/sysctl.d/20-barista-quiet.conf
sysctl -p /etc/sysctl.d/20-barista-quiet.conf || true

desired='loglevel=0 quiet splash vt.global_cursor_default=0 systemd.show_status=false rd.udev.log_level=0 systemd.journald.forward_to_console=0'
sed -i -E "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$desired\"|" /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
[[ -x /usr/local/lib/barista/quiet-grub.sh ]] && /usr/local/lib/barista/quiet-grub.sh || true
systemctl daemon-reload
echo OK
cat /etc/systemd/system.conf.d/barista-quiet.conf
grep CMDLINE_LINUX_DEFAULT /etc/default/grub
