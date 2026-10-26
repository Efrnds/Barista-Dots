#!/usr/bin/env bash
set -euo pipefail

if command -v superproductivity >/dev/null 2>&1; then
  CMD="superproductivity"
elif command -v super-productivity >/dev/null 2>&1; then
  CMD="super-productivity"
else
  CMD="superproductivity"
fi

if pgrep -xi "superproductiv" >/dev/null 2>&1 || pgrep -xi "super-productiv" >/dev/null 2>&1; then
  exit 0
fi

"$CMD" &
