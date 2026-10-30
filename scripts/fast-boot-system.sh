#!/usr/bin/env bash
# Rodar com sudo: cortes de boot que precisam de root
set -euo pipefail
[[ $EUID -eq 0 ]] || exec sudo -A "$0" "$@"

pacman -S --needed --noconfirm swaybg

systemctl disable --now NetworkManager-wait-online.service 2>/dev/null || true
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

if systemctl is-active --quiet NetworkManager; then
  systemctl disable --now systemd-networkd.service systemd-networkd-wait-online.service 2>/dev/null || true
  systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true
fi

if ! vgs --noheadings 2>/dev/null | grep -q .; then
  systemctl disable --now lvm2-monitor.service 2>/dev/null || true
fi

systemctl disable cups.service avahi-daemon.service 2>/dev/null || true
systemctl enable cups.socket avahi-daemon.socket 2>/dev/null || true
systemctl stop cups.service avahi-daemon.service 2>/dev/null || true

mkdir -p /etc/systemd/system/plymouth-quit.service.d
cat >/etc/systemd/system/plymouth-quit.service.d/delay.conf <<'E'
[Service]
ExecStart=
ExecStart=/bin/sh -c "sleep 1.2; /usr/bin/plymouth quit"
E
systemctl daemon-reload
echo "OK — reboot pra medir de novo (systemd-analyze)"
