#!/usr/bin/env bash
# Bootstrap one-liner: clone + install
set -euo pipefail

REPO="${DOTFILES_REPO:-https://github.com/Efrnds/Barista-Dots.git}"
TARGET="${DOTFILES_DIR:-$HOME/dotfiles}"

if ! command -v git >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm git
fi

if [[ -d "$TARGET/.git" ]]; then
  echo "Repo já existe em $TARGET — rodando update..."
  cd "$TARGET"
  git pull --rebase --autostash
  ./install.sh
else
  git clone "$REPO" "$TARGET"
  cd "$TARGET"
  chmod +x install.sh apply.sh import.sh update.sh
  ./install.sh
fi
