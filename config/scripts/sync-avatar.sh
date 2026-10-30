#!/usr/bin/env bash
# Mantém ~/.face, .face.icon, hypr/avatar e greeter cache = AccountsService IconFile
set -euo pipefail

icon=""
# 1) AccountsService (fonte da verdade do DMS setImage)
if command -v python3 >/dev/null; then
  icon="$(python3 - <<'PY'
import dbus, os, sys
try:
  bus=dbus.SystemBus()
  acc=dbus.Interface(bus.get_object("org.freedesktop.Accounts","/org/freedesktop/Accounts"),"org.freedesktop.Accounts")
  path=acc.FindUserByName(os.environ["USER"])
  props=dbus.Interface(bus.get_object("org.freedesktop.Accounts", path),"org.freedesktop.DBus.Properties")
  p=props.Get("org.freedesktop.Accounts.User","IconFile")
  print(p or "")
except Exception:
  pass
PY
)"
fi

# 2) fallbacks
if [[ -z "$icon" || ! -f "$icon" ]]; then
  for c in "$HOME/.face" "$HOME/.face.icon" /var/lib/AccountsService/icons/"$USER"; do
    [[ -f "$c" ]] && icon="$c" && break
  done
fi
[[ -n "$icon" && -f "$icon" ]] || exit 0

# Normalize to jpeg in home (readable)
tmp="$(mktemp "$HOME/.cache/avatar-XXXXXX.jpg")"
if command -v magick >/dev/null; then
  magick "$icon" -resize '512x512>' -strip "$tmp" 2>/dev/null || cp -f "$icon" "$tmp"
else
  cp -f "$icon" "$tmp"
fi

install -m644 "$tmp" "$HOME/.face"
install -m644 "$tmp" "$HOME/.face.icon"
# hypr avatar (dotfiles path is live)
if [[ -d "$HOME/dotfiles/config/hypr" ]]; then
  install -m644 "$tmp" "$HOME/dotfiles/config/hypr/avatar.jpg"
fi
# greeter prefers cacheDir/profile.jpg
for dest in /var/cache/dms-greeter/profile.jpg /var/cache/dms-greeter/profile.jpeg /var/cache/dms-greeter/profile.png; do
  dir=$(dirname "$dest")
  if [[ -d "$dir" && -w "$dir" ]]; then
    install -m644 "$tmp" /var/cache/dms-greeter/profile.jpg
    break
  fi
done

# Re-point AccountsService to ~/.face if it's on a ephemeral path
case "$icon" in
  /tmp/*|/run/user/*|/var/tmp/*)
    python3 - <<'PY' 2>/dev/null || true
import dbus, os
bus=dbus.SystemBus()
acc=dbus.Interface(bus.get_object("org.freedesktop.Accounts","/org/freedesktop/Accounts"),"org.freedesktop.Accounts")
path=acc.FindUserByName(os.environ["USER"])
user=dbus.Interface(bus.get_object("org.freedesktop.Accounts", path),"org.freedesktop.Accounts.User")
user.SetIconFile(os.path.expanduser("~/.face"))
PY
    ;;
esac

rm -f "$tmp"

# Ask DMS to refresh if running
dms ipc call profile getImage >/dev/null 2>&1 || true
