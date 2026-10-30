#!/usr/bin/env bash
# Re-copy DMS embedded UI into ~/.local/share/dms-ui and re-apply avatar patch.
# Run after `dms update` / package upgrade if the shell UI looks broken or outdated.
set -euo pipefail

ui="$HOME/.local/share/dms-ui"
tmpdir="$(mktemp -d /tmp/dms-ui-extract-XXXXXX)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

# Temporarily launch extract by copying from a fresh run dir if present, else
# ask dms to print version and use any live extract.
live=""
shopt -s nullglob
lives=(/run/user/"$(id -u)"/danklinux-shell/*/)
if [[ ${#lives[@]} -gt 0 ]]; then
  live="${lives[0]}"
fi

if [[ -z "$live" || ! -f "${live}shell.qml" ]]; then
  echo "No live DMS shell extract found. Start DMS once, then re-run." >&2
  exit 1
fi

rm -rf "$ui"
mkdir -p "$ui"
cp -a "$live". "$ui/"
chmod -R u+w "$ui"
"$HOME/.config/scripts/patch-dms-avatar.sh"
echo "Refreshed $ui from $live"
echo "Restart: systemctl --user restart dms"
