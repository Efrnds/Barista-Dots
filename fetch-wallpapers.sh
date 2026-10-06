#!/usr/bin/env bash
# Baixa o pack de wallpapers do Barista (repo separado).
# Uso: ./fetch-wallpapers.sh
#      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Efrnds/Barista-Dots/main/fetch-wallpapers.sh)"
set -euo pipefail

REPO_SSH="git@github.com:Efrnds/barista-wallpapers.git"
REPO_HTTPS="https://github.com/Efrnds/barista-wallpapers.git"
DEST="${BARISTA_WALLPAPERS_DIR:-${XDG_PICTURES_DIR:-$HOME/Imagens}/wallpapers}"

GREEN='\033[32m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

clone_url="$REPO_SSH"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -T git@github.com >/dev/null 2>&1; then
  clone_url="$REPO_HTTPS"
fi

mkdir -p "$(dirname "$DEST")"

if [[ -d "$DEST/.git" ]]; then
  echo -e "${BLUE}[*]${RESET} Atualizando wallpapers em $DEST"
  git -C "$DEST" pull --ff-only
elif [[ -d "$DEST" ]] && [[ -n "$(ls -A "$DEST" 2>/dev/null || true)" ]]; then
  echo -e "${YELLOW}[!]${RESET} $DEST já existe e não é um clone git."
  echo "    Mova/renomeie a pasta e rode de novo, ou:"
  echo "    git clone $REPO_HTTPS \"$DEST-barista\""
  exit 1
else
  echo -e "${BLUE}[*]${RESET} Clonando wallpapers → $DEST"
  git clone --depth 1 "$clone_url" "$DEST"
fi

count="$(find "$DEST" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.jfif' \) 2>/dev/null | wc -l)"
echo -e "${GREEN}[ok]${RESET} $count imagens em $DEST"
echo "Aponte o DMS (Settings → Wallpaper) para essa pasta, se ainda não estiver."
