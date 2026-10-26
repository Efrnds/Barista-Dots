#!/usr/bin/env bash
# Coding agent: Cursor / MAS + diagnóstico de crash
set -euo pipefail

SCRIPTS="${HOME}/.config/scripts"
PICKER="${SCRIPTS}/picker.sh"
CURSOR_APP="${HOME}/Applications/cursor.AppImage"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/barista"
mkdir -p "$LOG_DIR"

choice=$(printf '%s\n' \
  "🚀 Abrir Cursor" \
  "🤖 MAS trigger (menu)" \
  "📋 Diagnóstico: últimos crashes Cursor" \
  "📋 Diagnóstico: journal sessão" \
  "📄 Abrir log barista" \
  | "$PICKER" -p "Coding agent")

case "$choice" in
  "🚀 Abrir Cursor")
    "${SCRIPTS}/launch_cursor.sh" &
    ;;
  "🤖 MAS trigger (menu)")
    "${SCRIPTS}/mas-trigger.sh" &
    ;;
  "📋 Diagnóstico: últimos crashes Cursor")
    OUT="$LOG_DIR/cursor-crash.txt"
    {
      echo "=== $(date -Iseconds) Cursor crash diag ==="
      echo "--- AppImage ---"
      ls -la "$CURSOR_APP" 2>&1 || true
      echo "--- recent cursor logs ---"
      find "${HOME}/.config/Cursor/logs" "${HOME}/.cursor" -type f \( -name '*.log' -o -name '*crash*' \) 2>/dev/null \
        | head -20 | while read -r f; do
          echo "## $f"
          tail -n 40 "$f" 2>/dev/null || true
        done
      echo "--- coredumpctl (cursor) ---"
      coredumpctl list 2>/dev/null | rg -i 'cursor|AppImage' | tail -10 || true
    } >"$OUT"
    BARISTA_TERM_TITLE="Cursor crash" "${SCRIPTS}/run-in-term.sh" "less $(printf %q "$OUT")" &
    ;;
  "📋 Diagnóstico: journal sessão")
    OUT="$LOG_DIR/session-journal.txt"
    journalctl --user -b --no-pager -n 200 >"$OUT" 2>&1 || true
    BARISTA_TERM_TITLE="Journal" "${SCRIPTS}/run-in-term.sh" "less $(printf %q "$OUT")" &
    ;;
  "📄 Abrir log barista")
    BARISTA_TERM_TITLE="Logs" "${SCRIPTS}/run-in-term.sh" "ls -lt $(printf %q "$LOG_DIR"); echo" &
    ;;
esac
