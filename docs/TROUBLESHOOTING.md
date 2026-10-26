# Troubleshooting — Barista Dots (niri)

## Sessão / Ly

**Tela preta / não loga**

```bash
~/dotfiles/hooks/setup-session.sh
~/dotfiles/hooks/validate-login.sh
~/dotfiles/doctor.sh
```

No Ly, escolha **`Niri (DMS)`** (não Hyprland).

```bash
command -v niri-session
niri validate -c ~/.config/niri/config.kdl
```

## Terminal (Super+T)

```bash
chmod +x ~/.config/scripts/*.sh
grep -A2 'shell' ~/.config/alacritty/alacritty.toml
test -x ~/.local/bin/alacritty-tmux.sh
~/.config/scripts/launch_terminal.sh
```

Cores desalinhadas do DMS:

```bash
~/.config/scripts/sync-alacritty-theme-dms.sh
systemctl --user restart dms-alacritty-sync.path
```

## DMS não sobe

No `config.kdl` deve existir:

```kdl
spawn-at-startup "dms" "run"
```

Teste:

```bash
dms run
```

## Mouse não passa entre monitores

No niri, monitores precisam ficar **adjacentes** (sem gap). Ajuste em DMS → Displays ou `niri msg outputs`.

## Migrar / atualizar stack

```bash
~/dotfiles/migrate-stack.sh --yes   # primeira vez Hyprland → niri
~/dotfiles/update.sh                # dia a dia (pull + pacotes + apply)
```

## Doctor / smoke

```bash
~/dotfiles/doctor.sh
~/dotfiles/tests/smoke.sh
```
