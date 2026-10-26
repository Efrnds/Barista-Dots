#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=/dev/null
source "$(dirname "${BASH_SOURCE[0]}")/dotfiles-env.sh"

exec "$HOME/.config/scripts/launch_or_focus.sh" "$BROWSER_CLASS" "$BROWSER_CMD"
