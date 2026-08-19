#!/usr/bin/env bash
set -euo pipefail

CURSOR="$HOME/Applications/cursor.AppImage"
exec "$HOME/.config/hypr/scripts/launch_or_focus.sh" cursor "$CURSOR" --no-sandbox
