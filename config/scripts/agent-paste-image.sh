#!/usr/bin/env bash
# Fallback: pega image/png do clipboard, salva em /tmp e imprime o path
# (cole o path no prompt do agent se Ctrl+V falhar).
set -euo pipefail
out="/tmp/cursor-agent-clip-$(date +%s).png"
if ! wl-paste -t image/png >"$out" 2>/dev/null; then
  echo "Clipboard sem image/png" >&2
  exit 1
fi
if [[ ! -s "$out" ]]; then
  echo "Clipboard vazio" >&2
  rm -f "$out"
  exit 1
fi
# valida PNG
if ! python3 -c "import sys; b=open(sys.argv[1],'rb').read(8); sys.exit(0 if b==b'\\x89PNG\\r\\n\\x1a\\n' else 1)" "$out"; then
  echo "Não é PNG válido" >&2
  exit 1
fi
printf '%s\n' "$out"
# também copia o path como texto (Ctrl+Shift+V cola o caminho)
printf '%s' "$out" | wl-copy -t text/plain
notify-send "Imagem pronta" "$out (path no clipboard)" 2>/dev/null || true
