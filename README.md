# ☕ Barista Dots

Dotfiles com **symlinks** para Arch Linux — mesma config em várias máquinas.

## Stack oficial

| Componente | Versão / nota |
|------------|---------------|
| **Arch Linux** | base minimal |
| **niri** | scrollable tiling (Rust) |
| **DMS** | DankMaterialShell (bar/dock/lock/notifs) |
| **Alacritty** | terminal + tmux |
| **tmux** | prefixo `Ctrl+b` |
| **Thunar** | file manager |
| **greetd + dms-greeter** | login (alternativa: Ly via `session.conf`) |
| **Plymouth barista** | splash silencioso |
| **zen-browser** | opcional (`--extras`) |

---

## Requisitos

- Arch Linux instalado (base minimal)
- Usuário com **sudo**
- **Internet** (clone do repo + pacotes via `yay`)
- Não rode os scripts como root
- Locale do usuário configurado (`LANG`, ex. `pt_BR.UTF-8` ou `en_US.UTF-8`) — plugins DMS seguem o idioma

---

## Instalação

### One-liner (máquina nova)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Efrnds/Barista-Dots/main/setup.sh)"
```

O `setup.sh` clona em `~/dotfiles` e executa `./install.sh`.

### Manual

```bash
git clone https://github.com/Efrnds/Barista-Dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Migrar de Hyprland → niri

```bash
~/dotfiles/migrate-stack.sh --yes
```

### Flags do `install.sh`

| Flag | Efeito |
|------|--------|
| *(sem flags)* | Pacotes core + `apply.sh` + session + `chsh` zsh + `doctor.sh` |
| `--extras` | Instala também `packages/extras.txt` |
| `--minimal` | Só core; **não** altera shell padrão (`chsh`) |

### Pós-install (sudo, polish de boot)

```bash
~/dotfiles/plymouth/apply-boot-polish.sh
~/dotfiles/scripts/apply-silent-shutdown.sh
# opcional:
~/dotfiles/scripts/fast-boot-system.sh
```

---

## Primeiro boot

1. Reinicie após o `install.sh` / `migrate-stack.sh`
2. Splash **Plymouth barista** → greetd / dms-greeter (ou Ly)
3. Sessão **niri** + **DMS**
4. **Não** use Hyprland (stack antiga)

Session manager: edite `~/dotfiles/session.conf` (`dms-greeter` | `ly` | `auto`) e rode `~/dotfiles/hooks/setup-session.sh`.

---

## Keybinds essenciais

| Atalho | Ação |
|--------|------|
| `Super+T` | Terminal (Alacritty + tmux) |
| `Super+Space` | Launcher (DMS spotlight) |
| `Super+Alt+Space` | Menu Barista (Setup/Update/layouts/VPN…) |
| `Super+B` | Browser (zen-browser) |
| `Super+C` | Editor (Cursor) |
| `Super+E` | Thunar |
| `Super+L` | Lock (fingerprint se enrollado) |
| `Super+Escape` | Powermenu DMS |
| `Super+O` | Overview niri |

Lista completa: [docs/KEYBINDS.md](docs/KEYBINDS.md)

---

## Customizar

Edite **`~/.config/dotfiles/user.conf`** (criado no primeiro `apply.sh`, não versionado):

```bash
TERMINAL_CMD="alacritty"
TERMINAL_CLASS="Alacritty"
BROWSER_CMD="zen-browser"
BROWSER_CLASS="zen"
FILE_MANAGER_CMD="thunar"
CURSOR_APP="${HOME}/Applications/cursor.AppImage"
```

Depois: `~/dotfiles/apply.sh`.

Pastas XDG (`Pictures` / `Imagens`, etc.) vêm de `~/.config/user-dirs.dirs` — wallpapers e bookmarks do Thunar respeitam o idioma do sistema.

---

## O que cada peça faz

| Área | Doc |
|------|-----|
| Plugins da barra (Hub, Freela, OBS, RTK, LAN IP) + **i18n** | [docs/PLUGINS.md](docs/PLUGINS.md) |
| Troca de avatar nas Settings do DMS | [docs/AVATAR.md](docs/AVATAR.md) |
| Boot Plymouth, greetd, fingerprint, tela preta | [docs/BOOT-LOGIN.md](docs/BOOT-LOGIN.md) |
| Problemas comuns | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| Pacotes | [packages/README.md](packages/README.md) |

---

## Scripts

| Script | Função |
|--------|--------|
| `migrate-stack.sh` | Migra Hyprland → niri |
| `apply.sh` | Symlinks + hooks pós-apply |
| `import.sh` | Copia configs locais → repo |
| `update.sh` | `git pull` + sync pacotes + apply + doctor |
| `install.sh` | Máquina nova |
| `doctor.sh` | Diagnóstico |
| `tests/smoke.sh` | Smoke tests |
| `config/scripts/prepare-avatar.sh` | Resize avatar ≤1 MiB |
| `config/scripts/refresh-dms-ui.sh` | Reaplica patch de UI após update do DMS |
| `plymouth/apply-boot-polish.sh` | Tema barista + GRUB quiet |
| `scripts/apply-silent-shutdown.sh` | Shutdown sem spam |

---

## O que é versionado

| Repo | Destino |
|------|---------|
| `config/niri/` | `~/.config/niri/` |
| `config/alacritty/` | `~/.config/alacritty/` |
| `config/scripts/` | `~/.config/scripts/` |
| `config/tmux/` | `~/.config/tmux/` |
| `config/DankMaterialShell/` | `~/.config/DankMaterialShell/` |
| `dms-plugins/` | `~/.config/DankMaterialShell/plugins/` (symlink) |
| `local-bin/` | `~/.local/bin/` |
| `systemd/user/` | `~/.config/systemd/user/` |
| `plymouth/` | instalado via script (system) |
| `greetd/` | referência / apply com sudo |
| `home/.zshrc`, etc. | `~/` |

**Não versionado:** wallpapers grandes, secrets, `user.conf`, `~/.local/share/dms-ui` (gerado localmente).
