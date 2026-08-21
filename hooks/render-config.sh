#!/usr/bin/env bash
# Renderiza configs a partir de templates (antes dos symlinks no apply.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/user.conf"

mkdir -p "$ROOT/config/foot" "$ROOT/config/spicetify" "$(dirname "$USER_CONF")"

if [[ ! -f "$USER_CONF" ]]; then
  cp "$ROOT/templates/user.conf.example" "$USER_CONF"
  echo "[render-config] criado $USER_CONF"
fi

export HOME
# envsubst precisa das aspas simples para expandir ${HOME} no template, não no shell
# shellcheck disable=SC2016
envsubst '${HOME}' < "$ROOT/templates/foot.ini.in" > "$ROOT/config/foot/foot.ini"
# shellcheck disable=SC2016
envsubst '${HOME}' < "$ROOT/templates/spicetify-config-xpui.ini.in" > "$ROOT/config/spicetify/config-xpui.ini"

echo "[render-config] foot.ini + spicetify config renderizados"
