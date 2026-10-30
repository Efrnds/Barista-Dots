#!/usr/bin/env bash
# Shrink any image to AccountsService's 1 MiB limit, write ~/.face, sync copies.
# Prints the prepared absolute path on stdout (for DMS PortalService).
set -euo pipefail

src="${1:-}"
if [[ -z "$src" || ! -f "$src" ]]; then
  echo "usage: prepare-avatar.sh <image>" >&2
  exit 1
fi

mkdir -p "$HOME/.cache"
out="$HOME/.face"
max_bytes=$((900 * 1024)) # stay under AccountsService 1 MiB hard limit
tmp="$(mktemp "$HOME/.cache/avatar-prep-XXXXXX.jpg")"
trap 'rm -f "$tmp"' EXIT

resize_to() {
  local px="$1"
  if command -v magick >/dev/null; then
    magick "$src" -auto-orient -resize "${px}x${px}>" -strip -quality 88 "$tmp"
  elif command -v convert >/dev/null; then
    convert "$src" -auto-orient -resize "${px}x${px}>" -strip -quality 88 "$tmp"
  else
    cp -f "$src" "$tmp"
  fi
}

ok=0
for px in 512 384 256 192 128; do
  resize_to "$px"
  if [[ "$(stat -c%s "$tmp")" -le "$max_bytes" ]]; then
    ok=1
    break
  fi
done

if [[ "$ok" -ne 1 ]]; then
  # last resort: tiny
  resize_to 96
fi

if [[ "$(stat -c%s "$tmp")" -gt $((1024 * 1024)) ]]; then
  echo "prepare-avatar: still too large after resize" >&2
  exit 2
fi

install -m644 "$tmp" "$out"
install -m644 "$tmp" "$HOME/.face.icon"
if [[ -d "$HOME/dotfiles/config/hypr" ]]; then
  install -m644 "$tmp" "$HOME/dotfiles/config/hypr/avatar.jpg"
fi
if [[ -d /var/cache/dms-greeter && -w /var/cache/dms-greeter ]]; then
  install -m644 "$tmp" /var/cache/dms-greeter/profile.jpg
fi

# Push into AccountsService from the prepared (small) file
if command -v python3 >/dev/null; then
  python3 - <<'PY' 2>/dev/null || true
import dbus, os
bus = dbus.SystemBus()
acc = dbus.Interface(
    bus.get_object("org.freedesktop.Accounts", "/org/freedesktop/Accounts"),
    "org.freedesktop.Accounts",
)
path = acc.FindUserByName(os.environ["USER"])
user = dbus.Interface(
    bus.get_object("org.freedesktop.Accounts", path),
    "org.freedesktop.Accounts.User",
)
user.SetIconFile(os.path.expanduser("~/.face"))
PY
fi

printf '%s\n' "$out"
