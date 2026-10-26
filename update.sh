#!/usr/bin/env bash
# git pull + sync pacotes da stack niri + apply
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

echo "[update] git pull..."
git pull --rebase --autostash

echo "[update] sync pacotes core (faltantes)..."
while read -r pkg; do
  [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
  if ! pacman -Qi "$pkg" &>/dev/null; then
    echo "[update] instalando $pkg..."
    yay -S --needed --noconfirm "$pkg" || true
  fi
done < "$DOTFILES/packages/core.txt"

if [[ "${UPDATE_REMOVE_OBSOLETE:-1}" == "1" ]] && [[ -f "$DOTFILES/packages/obsolete.txt" ]]; then
  echo "[update] removendo pacotes obsolete (se instalados)..."
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if pacman -Qi "$pkg" &>/dev/null; then
      echo "[update] -Rns $pkg"
      sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null \
        || sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null \
        || true
    fi
  done < "$DOTFILES/packages/obsolete.txt"
fi

echo "[update] apply..."
"$DOTFILES/apply.sh"

echo "[update] session manager..."
"$DOTFILES/hooks/setup-session.sh"

echo "[update] doctor..."
"$DOTFILES/doctor.sh" || true

echo "[update] ok — no Ly use a sessão: Niri (DMS)"
