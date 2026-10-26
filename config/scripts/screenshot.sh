#!/usr/bin/env bash
# dms screenshot + clipboard só com image/png (sem path/uri-list).
set -euo pipefail
MODE="${1:-region}"
case "$MODE" in
  region|full|window|last|all|output|scroll) ;;
  *) MODE=region ;;
esac
shift || true

tmp=$(mktemp /tmp/barista-shot-XXXXXX.json)
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

if dms screenshot "$MODE" --json "$@" >"$tmp" 2>/tmp/barista-shot.err; then
  file=$(python3 - "$tmp" <<'PY'
import json,sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
for k in ("path","file","filename","output"):
  v=d.get(k)
  if isinstance(v,str) and v:
    print(v); break
else:
  for v in d.values():
    if isinstance(v,str) and v.endswith((".png",".jpg",".jpeg",".webp")):
      print(v); break
PY
)
  if [[ -n "${file:-}" && -f "$file" ]]; then
    wl-copy -t image/png <"$file"
  fi
else
  dms screenshot "$MODE" "$@" || true
fi
