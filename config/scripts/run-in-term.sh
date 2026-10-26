#!/usr/bin/env bash
# Abre Alacritty rodando um comando via script temporário como shell.
# Não usa -e (conflita com shell/tmux do config padrão).
set -euo pipefail

TITLE="${BARISTA_TERM_TITLE:-Barista}"
CMD="${*:-true}"
COLORS="${HOME}/.config/alacritty/colors.toml"
TMPDIR="${XDG_RUNTIME_DIR:-/tmp}"
CFG="$(mktemp "$TMPDIR/alacritty-barista-XXXXXX.toml")"
RUN="$(mktemp "$TMPDIR/barista-run-XXXXXX.sh")"

# Comando e título ficam DENTRO do script (não dependem de env do Alacritty)
{
  echo '#!/usr/bin/env bash'
  echo 'set +e'
  echo 'export TERM="${TERM:-alacritty}"'
  printf 'TITLE=%q\n' "$TITLE"
  printf 'CMD=%q\n' "$CMD"
  cat <<'EOS'
clear
echo "==> $TITLE"
echo "==> $(date -Iseconds)"
echo
# shellcheck disable=SC2086
eval "$CMD"
ec=$?
echo
echo "[exit $ec]"
read -r -p "Enter para fechar… " _
exit $ec
EOS
} >"$RUN"
chmod +x "$RUN"

{
  echo '# ephemeral — barista run-in-term'
  if [[ -f "$COLORS" ]]; then
    printf '[general]\nimport = ["%s"]\n\n' "$COLORS"
  fi
  # Escapa path do RUN pra TOML
  printf '%s\n' \
    '[window]' \
    'padding = { x = 15, y = 15 }' \
    'decorations = "None"' \
    '' \
    '[font]' \
    'size = 11.0' \
    '' \
    '[font.normal]' \
    'family = "JetBrainsMono Nerd Font"' \
    '' \
    '[terminal]' \
    "shell = { program = \"${RUN}\" }"
} >"$CFG"

alacritty \
  --config-file "$CFG" \
  --class barista-run \
  --title "$TITLE" \
  || true

rm -f "$CFG" "$RUN"
