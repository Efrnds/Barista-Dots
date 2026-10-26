#!/usr/bin/env bash
set -euo pipefail

toast() {
  local m="$1"
  dms ipc call toast info "$m" >/dev/null 2>&1 || notify-send "WARP" "$m"
}

if ! command -v warp-cli >/dev/null; then
  toast "warp-cli não instalado"
  exit 1
fi

# Garante daemon (não enabled no boot — sobe sob demanda)
if ! systemctl is-active --quiet warp-svc 2>/dev/null; then
  sudo systemctl start warp-svc.service 2>/dev/null || true
  sleep 1
fi

status=$(warp-cli status 2>/dev/null || true)
if echo "$status" | grep -qi 'Connected'; then
  warp-cli disconnect >/dev/null 2>&1 || true
  toast "WARP desconectado"
elif echo "$status" | grep -qi 'Disconnected\|Registration'; then
  warp-cli connect >/dev/null 2>&1 || warp-cli --accept-tos connect >/dev/null 2>&1 || true
  toast "WARP conectando…"
else
  warp-cli --accept-tos connect >/dev/null 2>&1 || warp-cli connect >/dev/null 2>&1 || true
  toast "WARP: $(warp-cli status 2>/dev/null | head -1 || echo tentando)"
fi
