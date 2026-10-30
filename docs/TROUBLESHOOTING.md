# Troubleshooting — Barista Dots (niri + DMS)

## Diagnóstico rápido

```bash
~/dotfiles/doctor.sh
~/dotfiles/tests/smoke.sh
```

## Sessão / login

**Tela preta / não loga**

```bash
~/dotfiles/hooks/setup-session.sh
~/dotfiles/hooks/validate-login.sh
~/dotfiles/doctor.sh
command -v niri-session
niri validate -c ~/.config/niri/config.kdl
```

- Stack oficial: **niri + DMS** (não Hyprland).
- Session manager: `session.conf` → `dms-greeter` (greetd) ou `ly`.
- Detalhes de boot/flash: [BOOT-LOGIN.md](./BOOT-LOGIN.md)

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

Texto ilegível (fg = fundo): confira theme sync e `on_surface` no tema Dank.

## DMS não sobe

DMS deve ser gerenciado por **systemd user** (não spawn duplicado no niri):

```bash
systemctl --user status dms
systemctl --user restart dms
dms run   # debug em foreground
```

## Avatar não muda nas Settings

Causa comum: foto **> 1 MiB** rejeitada pelo AccountsService.  
Guia completo: [AVATAR.md](./AVATAR.md)

```bash
journalctl --user -u dms -b --grep 'too large'
systemctl --user show dms -p Environment   # DMS_SHELL_DIR=.../dms-ui
~/dotfiles/config/scripts/refresh-dms-ui.sh
systemctl --user restart dms
```

## Plugins / idioma

UI dos plugins segue o **locale do usuário** (`translations/pt.json`, etc.).  
Ver [PLUGINS.md](./PLUGINS.md).

```bash
echo $LANG
systemctl --user restart dms
```

## Mouse não passa entre monitores

No niri, monitores precisam ficar **adjacentes** (sem gap). Ajuste em DMS → Displays ou `niri msg outputs`.

## Fingerprint

```bash
fprintd-list "$USER"
# enroll se vazio:
fprintd-enroll
```

Lock: `Mod+L`. Boot/autologin normalmente **sem** prompt de digital (por design).

USB Validity: se falhar com timeout, desative autosuspend do dispositivo (udev/TLP denylist) e reinicie.

## Migrar / atualizar

```bash
~/dotfiles/migrate-stack.sh --yes   # Hyprland → niri (1ª vez)
~/dotfiles/update.sh                # pull + pacotes + apply + doctor
```

Após upgrade do pacote `dms-shell`:

```bash
~/dotfiles/config/scripts/refresh-dms-ui.sh
systemctl --user restart dms
```
