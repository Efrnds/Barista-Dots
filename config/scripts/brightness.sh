#!/usr/bin/env bash

case "$1" in
  up) dms ipc call brightness increment 5 "" >/dev/null 2>&1 || true ;;
  down) dms ipc call brightness decrement 5 "" >/dev/null 2>&1 || true ;;
  *) exit 0 ;;
esac
