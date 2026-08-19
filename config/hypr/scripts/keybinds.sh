#!/usr/bin/env bash
# Cheat-sheet de atalhos — Hyprland (hyprctl) + tmux. Super+Shift+/ abre painel DMS.
set -euo pipefail

PICKER="$HOME/.config/hypr/scripts/picker.sh"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"

build_hypr_list() {
  hyprctl binds -j 2>/dev/null | python3 -c "
import json, sys

MODS = [
    (64, 'Super'),
    (32, 'Hyper'),
    (16, 'Mod5'),
    (8, 'Alt'),
    (4, 'Ctrl'),
    (2, 'Mod3'),
    (1, 'Shift'),
]

def mod_str(mask):
    if mask == 0:
        return ''
    parts = [name for bit, name in MODS if mask & bit]
    return ' + '.join(parts)

lines = []
for b in json.load(sys.stdin):
    if b.get('locked') or b.get('mouse'):
        continue
    key = b.get('key') or ''
    if not key or key.startswith('switch:'):
        continue
    mods = mod_str(b.get('modmask', 0))
    desc = (b.get('description') or '').strip()
    disp = b.get('dispatcher') or ''
    arg = str(b.get('arg') or '')
    if desc:
        action = desc
    elif disp == '__lua':
        action = 'lua bind'
    elif disp:
        action = f'{disp} {arg}'.strip()
    else:
        action = 'bind'
    label = f'{mods} + {key}'.strip(' +')
    lines.append(f'Hypr  {label}  ->  {action}')

for line in sorted(set(lines), key=str.lower):
    print(line)
" 2>/dev/null || true
}

build_tmux_list() {
  cat <<'EOF'
tmux  Ctrl+b + ?       ->  ajuda
tmux  Ctrl+b + |       ->  split horizontal
tmux  Ctrl+b + -       ->  split vertical
tmux  Ctrl+b + h/j/k/l  ->  navegar panes
tmux  Ctrl+b + z       ->  zoom pane
tmux  Ctrl+b + x       ->  fechar pane
tmux  Ctrl+b + c       ->  nova janela
tmux  Ctrl+b + d       ->  detach
tmux  Ctrl+b + r       ->  reload config
tmux  Ctrl+b + S       ->  salvar sessão (resurrect)
tmux  Ctrl+b + R       ->  restaurar sessão (resurrect)
EOF
}

LISTA="$(build_hypr_list; build_tmux_list)"

if [[ -z "$LISTA" ]]; then
  if [[ -f "$DOTFILES/docs/KEYBINDS.md" ]]; then
    foot -e "${EDITOR:-less}" "$DOTFILES/docs/KEYBINDS.md"
  else
    notify-send "Atalhos" "hyprctl indisponível — abra docs/KEYBINDS.md"
  fi
  exit 0
fi

echo "$LISTA" | "$PICKER" -p "Atalhos (Hypr + tmux)" >/dev/null || true
