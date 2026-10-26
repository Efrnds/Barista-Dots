#!/usr/bin/env bash
# Anexa imagem no cursor-agent.
#
# Por que path em ~/.cache não vira [Imagem #N]: o agent SÓ auto-converte
# arquivos sob /tmp (e TMPDIR). Por isso sempre copiamos pra
# /tmp/cursor-agent-clipboard/ e colamos ESSE path no prompt do agent.
set -euo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/dms/clipboard"
OUTDIR="${TMPDIR:-/tmp}/cursor-agent-clipboard"
mkdir -p "$OUTDIR"
OUT="$OUTDIR/attach-$(date +%s%N).png"

src=""
if [[ -n "${1:-}" && -f "$1" ]]; then
  src="$1"
elif wl-paste -l 2>/dev/null | rg -qx 'image/png'; then
  if wl-paste -t image/png >"$OUT" 2>/dev/null && [[ -s "$OUT" ]]; then
    src="$OUT"
  fi
fi

if [[ -z "$src" ]]; then
  txt=$(wl-paste -t text/plain 2>/dev/null || true)
  txt="${txt%%$'\n'*}"
  if [[ "$txt" == file://* ]]; then
    txt=$(python3 -c "import sys,urllib.parse; print(urllib.parse.unquote(sys.argv[1].removeprefix('file://')))" "$txt")
  fi
  if [[ -n "$txt" && -f "$txt" && "$txt" =~ \.(png|jpe?g|gif|webp|bmp)$ ]]; then
    src="$txt"
  fi
fi

if [[ -z "$src" && -d "$CACHE" ]]; then
  src=$(find "$CACHE" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) -printf '%T@ %p\n' 2>/dev/null \
    | sort -nr | head -1 | cut -d' ' -f2- || true)
fi

if [[ -z "${src:-}" || ! -f "$src" ]]; then
  notify-send "Agent imagem" "Nenhuma imagem no clipboard/cache" 2>/dev/null || true
  echo "Nenhuma imagem encontrada" >&2
  exit 1
fi

[[ "$src" == "$OUT" ]] || cp -f "$src" "$OUT"

python3 - "$OUT" <<'PY' || { echo "arquivo inválido" >&2; exit 1; }
import sys
b=open(sys.argv[1],"rb").read(12)
ok=(b[:8]==b"\x89PNG\r\n\x1a\n") or (b[:3]==b"\xff\xd8\xff") or (b[:3]==b"GIF") or (b[:4]==b"RIFF" and b[8:12]==b"WEBP")
sys.exit(0 if ok else 1)
PY

# PNG limpo no clipboard (bonus pro Ctrl+V nativo)
wl-copy -t image/png <"$OUT"

mapfile -t PANES < <(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
  | awk '$2=="cursor-agent"{print $1}')

if [[ ${#PANES[@]} -eq 0 ]]; then
  # fallback: path como texto + tenta colar na janela focada
  printf '%s' "$OUT" | wl-copy -t text/plain
  if command -v wtype >/dev/null; then
    sleep 0.05
    wtype -M ctrl -M shift v -m shift -m ctrl
  fi
  notify-send "Agent imagem" "Sem pane tmux. Cole: $OUT" 2>/dev/null || true
  echo "OK file=$OUT (no pane; path no clipboard)"
  exit 0
fi

for pane in "${PANES[@]}"; do
  # Cola o path /tmp no prompt — agent promove pra [Image #N]
  tmux set-buffer -b agentimg "$OUT"
  tmux paste-buffer -b agentimg -t "$pane"
  sleep 0.05
  # Também tenta Ctrl+V (image/png) — se o TUI aceitar, anexa direto
  tmux send-keys -t "$pane" C-v
done

notify-send "Agent imagem" "[Image] via /tmp → ${#PANES[@]} agent(s)" 2>/dev/null || true
echo "OK panes=${PANES[*]} file=$OUT"
