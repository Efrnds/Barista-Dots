#!/usr/bin/env bash
# Lança Spotifast se não estiver rodando.
set -euo pipefail

if pgrep -x "spotifast" >/dev/null 2>&1; then
  exit 0
fi

spotifast &
