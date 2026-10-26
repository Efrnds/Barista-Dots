#!/usr/bin/env bash
# Histórico de clipboard — usa o UI nativo do DMS (cliphist por baixo).
set -euo pipefail
exec dms ipc call clipboard toggle
