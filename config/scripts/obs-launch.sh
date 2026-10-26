#!/usr/bin/env bash
# Abre OBS e sobe o scene-router só enquanto o OBS estiver rodando.
set -euo pipefail

systemctl --user start obs-scene-router.service 2>/dev/null || true

obs "$@" &
OBS_PID=$!
wait "$OBS_PID" || true

systemctl --user stop obs-scene-router.service 2>/dev/null || true
