#!/usr/bin/env bash
# Instala tmux-resurrect em ~/.local/share (fora do symlink do repo).
set -euo pipefail

PLUGIN_DIR="${HOME}/.local/share/tmux/plugins/tmux-resurrect"
URL="https://github.com/tmux-plugins/tmux-resurrect"

if [[ -d "$PLUGIN_DIR/.git" ]]; then
  echo "[setup-tmux] tmux-resurrect ok"
  exit 0
fi

mkdir -p "$(dirname "$PLUGIN_DIR")"
echo "[setup-tmux] cloning tmux-resurrect..."
git clone --depth 1 "$URL" "$PLUGIN_DIR"
echo "[setup-tmux] done — Ctrl+b Ctrl+s salvar | Ctrl+b Ctrl+r restaurar"
