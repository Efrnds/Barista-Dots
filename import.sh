#!/usr/bin/env bash
# Importa configs da máquina atual PARA o repo (antes de commitar).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLUE='\033[34m'
GREEN='\033[32m'
RESET='\033[0m'

rsync_dir() {
  local src="$1" dest="$2"
  shift 2
  [[ -d "$src" ]] || { echo "[skip] $src"; return 0; }
  mkdir -p "$dest"
  rsync -a --delete "$@" "$src/" "$dest/"
  echo -e "${GREEN}[import]${RESET} $src -> $dest"
}

echo -e "${BLUE}=== Importando configs para $DOTFILES ===${RESET}"

rsync_dir "$HOME/.config/niri" "$DOTFILES/config/niri"
rsync_dir "$HOME/.config/alacritty" "$DOTFILES/config/alacritty" \
  --exclude='alacritty.toml'  # gerado por template
rsync_dir "$HOME/.config/scripts" "$DOTFILES/config/scripts" \
  --exclude='__pycache__/'
rsync_dir "$HOME/.config/tmux" "$DOTFILES/config/tmux"
rsync_dir "$HOME/.config/DankMaterialShell" "$DOTFILES/config/DankMaterialShell" \
  --exclude='.firstlaunch' --exclude='.changelog-*'
rsync_dir "$HOME/.config/nvim" "$DOTFILES/config/nvim"
rsync_dir "$HOME/.config/btop" "$DOTFILES/config/btop"
rsync_dir "$HOME/.config/cava" "$DOTFILES/config/cava"
rsync_dir "$HOME/.config/fastfetch" "$DOTFILES/config/fastfetch"
rsync_dir "$HOME/.config/spicetify" "$DOTFILES/config/spicetify"

# Wallpaper legado
for f in current_wallpaper.jpg current_wallpaper.mp4 avatar.jpg; do
  [[ -f "$HOME/.config/hypr/$f" ]] && mkdir -p "$DOTFILES/config/hypr" && cp -a "$HOME/.config/hypr/$f" "$DOTFILES/config/hypr/$f"
done

[[ -f "$HOME/.config/starship.toml" ]] && cp -a "$HOME/.config/starship.toml" "$DOTFILES/config/starship.toml"

mkdir -p "$DOTFILES/systemd/user"
for unit in dms-alacritty-sync.path dms-alacritty-sync.service obs-scene-router.service; do
  [[ -f "$HOME/.config/systemd/user/$unit" ]] && cp -a "$HOME/.config/systemd/user/$unit" "$DOTFILES/systemd/user/"
done

mkdir -p "$DOTFILES/local-bin"
for bin in alacritty-tmux.sh alacritty-tmux-dev.sh alacritty-tmux-ssh.sh; do
  src="$HOME/.local/bin/$bin"
  [[ -f "$src" ]] && cp -a "$src" "$DOTFILES/local-bin/$bin"
done

mkdir -p "$DOTFILES/home"
for f in .zshrc .bashrc .gitconfig; do
  [[ -f "$HOME/$f" ]] && cp -a "$HOME/$f" "$DOTFILES/home/$f"
done

if [[ -r /etc/ly/config.ini ]]; then
  mkdir -p "$DOTFILES/etc/ly"
  cp -a /etc/ly/config.ini "$DOTFILES/etc/ly/config.ini"
  echo -e "${GREEN}[import]${RESET} /etc/ly/config.ini"
fi
if [[ -d /etc/ly/custom-sessions ]]; then
  mkdir -p "$DOTFILES/etc/ly/custom-sessions"
  cp -a /etc/ly/custom-sessions/. "$DOTFILES/etc/ly/custom-sessions/" 2>/dev/null || true
fi

if command -v pacman >/dev/null 2>&1; then
  mkdir -p "$DOTFILES/packages"
  # extras = explicit packages minus core/obsolete
  python3 - <<'PY' "$DOTFILES"
from pathlib import Path
import subprocess, sys
root = Path(sys.argv[1])
core = {l.strip() for l in (root/"packages/core.txt").read_text().splitlines() if l.strip() and not l.startswith("#")}
obsolete = set()
ob = root/"packages/obsolete.txt"
if ob.exists():
  obsolete = {l.strip() for l in ob.read_text().splitlines() if l.strip() and not l.startswith("#")}
pkgs = subprocess.check_output(["pacman","-Qqe"], text=True).splitlines()
extras = sorted(p for p in pkgs if p not in core and p not in obsolete)
(root/"packages/extras.txt").write_text("\n".join(extras)+"\n")
print(f"[import] packages/extras.txt ({len(extras)} pacotes)")
PY
fi

echo -e "${GREEN}=== Import concluído. Revise com git diff e commit. ===${RESET}"
