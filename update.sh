#!/usr/bin/env bash
# git pull + apply (use na outra máquina)
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES"

echo "[update] git pull..."
git pull --rebase --autostash

echo "[update] apply..."
"$DOTFILES/apply.sh"

echo "[update] session manager..."
"$DOTFILES/hooks/setup-session.sh"

echo "[update] doctor..."
"$DOTFILES/doctor.sh" || true
