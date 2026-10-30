#!/usr/bin/env bash
# Remove echoes "Carregando..." do grub.cfg (zero texto entre firmware e Plymouth).
set -euo pipefail
CFG=/boot/grub/grub.cfg
[[ -f "$CFG" ]] || exit 0
# Comenta qualquer echo de loading gerado pelo 10_linux
sed -i -E \
  -e "s/^([[:space:]]*)echo[[:space:]]+'Carregando[^']*'/\1# quiet: &/" \
  -e "s/^([[:space:]]*)echo[[:space:]]+\"Carregando[^\"]*\"/\1# quiet: &/" \
  -e "s/^([[:space:]]*)echo[[:space:]]+'Loading[^']*'/\1# quiet: &/" \
  -e "s/^([[:space:]]*)echo[[:space:]]+\"Loading[^\"]*\"/\1# quiet: &/" \
  "$CFG"
