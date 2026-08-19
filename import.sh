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

HYPR_EX=(
  --exclude='current_wallpaper.jpg'
  --exclude='current_wallpaper.mp4'
  --exclude='current_wallpaper.webp'
  --exclude='avatar.jpg'
  --exclude='.dms-backups/'
)

rsync_dir "$HOME/.config/hypr" "$DOTFILES/config/hypr" "${HYPR_EX[@]}"
rsync_dir "$HOME/.config/foot" "$DOTFILES/config/foot"
rsync_dir "$HOME/.config/tmux" "$DOTFILES/config/tmux"
rsync_dir "$HOME/.config/DankMaterialShell" "$DOTFILES/config/DankMaterialShell" \
  --exclude='.firstlaunch' --exclude='.changelog-*'
rsync_dir "$HOME/.config/nvim" "$DOTFILES/config/nvim"
rsync_dir "$HOME/.config/yazi" "$DOTFILES/config/yazi"
rsync_dir "$HOME/.config/btop" "$DOTFILES/config/btop"
rsync_dir "$HOME/.config/cava" "$DOTFILES/config/cava"
rsync_dir "$HOME/.config/fastfetch" "$DOTFILES/config/fastfetch"
rsync_dir "$HOME/.config/spicetify" "$DOTFILES/config/spicetify"

[[ -f "$HOME/.config/starship.toml" ]] && cp -a "$HOME/.config/starship.toml" "$DOTFILES/config/starship.toml"

mkdir -p "$DOTFILES/systemd/user"
for unit in dms-foot-sync.path dms-foot-sync.service; do
  [[ -f "$HOME/.config/systemd/user/$unit" ]] && cp -a "$HOME/.config/systemd/user/$unit" "$DOTFILES/systemd/user/"
done

mkdir -p "$DOTFILES/local-bin"
for bin in foot-tmux.sh foot-tmux-dev.sh foot-tmux-ssh.sh sync-foot-theme-dms.sh; do
  src="$HOME/.local/bin/$bin"
  [[ -f "$src" ]] && cp -a "$src" "$DOTFILES/local-bin/$bin"
  src="$HOME/.config/hypr/scripts/$bin"
  [[ -f "$src" ]] && cp -a "$src" "$DOTFILES/local-bin/$bin"
done
# sync-foot-theme-dms lives in hypr/scripts
[[ -f "$HOME/.config/hypr/scripts/sync-foot-theme-dms.sh" ]] && \
  cp -a "$HOME/.config/hypr/scripts/sync-foot-theme-dms.sh" "$DOTFILES/local-bin/sync-foot-theme-dms.sh"

mkdir -p "$DOTFILES/home"
for f in .zshrc .bashrc .gitconfig; do
  [[ -f "$HOME/$f" ]] && cp -a "$HOME/$f" "$DOTFILES/home/$f"
done

# Ly (system config — precisa sudo pra ler/gravar)
if [[ -r /etc/ly/config.ini ]]; then
  mkdir -p "$DOTFILES/etc/ly"
  cp -a /etc/ly/config.ini "$DOTFILES/etc/ly/config.ini"
  echo -e "${GREEN}[import]${RESET} /etc/ly/config.ini"
fi
if [[ -d /etc/ly/custom-sessions ]]; then
  mkdir -p "$DOTFILES/etc/ly/custom-sessions"
  cp -a /etc/ly/custom-sessions/. "$DOTFILES/etc/ly/custom-sessions/" 2>/dev/null || true
fi

# Atualiza lista de pacotes extras (pacman + AUR via pacman -Q)
if command -v pacman >/dev/null 2>&1; then
  mkdir -p "$DOTFILES/packages"
  pacman -Qqe > "$DOTFILES/packages/extras.txt"
  echo -e "${GREEN}[import]${RESET} packages/extras.txt ($(wc -l < "$DOTFILES/packages/extras.txt") pacotes)"
fi

echo -e "${GREEN}=== Import concluído. Revise com git diff e commit. ===${RESET}"
