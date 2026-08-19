#!/usr/bin/env bash

case "$1" in
  up) dms ipc call audio increment 5 >/dev/null 2>&1 || true ;;
  down) dms ipc call audio decrement 5 >/dev/null 2>&1 || true ;;
  mute) dms ipc call audio mute >/dev/null 2>&1 || true ;;
  *) exit 0 ;;
esac
