#!/usr/bin/env bash
set -euo pipefail
exec sudo tee /etc/pam.d/greetd < /home/eduardo/dotfiles/greetd/greetd.pam >/dev/null
