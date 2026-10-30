#!/usr/bin/env bash
# Alternativa: dms-greeter (niri) → tuigreet (TTY). Elimina flash de 2 compositors.
# Stack padrão do repo é autologin + dms-greeter; use isto só se preferir TTY.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

[[ $EUID -eq 0 ]] || exec sudo -A "$0" "$@"

install -d /etc/greetd
cp -a /etc/greetd/config.toml "/etc/greetd/config.toml.backup-tuigreet-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

if [[ -f "$ROOT/greetd/config.toml.tuigreet" ]]; then
  sed "s|@USER@|${TARGET_USER}|g; s|@HOME@|${TARGET_HOME}|g" \
    "$ROOT/greetd/config.toml.tuigreet" >/etc/greetd/config.toml
  chmod 644 /etc/greetd/config.toml
else
  echo "faltando greetd/config.toml.tuigreet" >&2
  exit 1
fi

install -m644 "$ROOT/greetd/greetd.pam" /etc/pam.d/greetd

usermod -aG video,input greeter 2>/dev/null || true

# Impede dms-greeter sync de reescrever o greetd
systemctl --user --machine="${TARGET_USER}@" mask dms-greeter-sync.service dms-greeter-sync.path 2>/dev/null || true

echo "=== /etc/greetd/config.toml ==="
cat /etc/greetd/config.toml
echo
echo "OK. Próximo boot: tuigreet no TTY → niri (1 compositor)."
