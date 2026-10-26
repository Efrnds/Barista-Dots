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
| **Ly** | display manager (`ly@tty1`) |
| **zen-browser** | opcional (`--extras`) |

---

## Requisitos

- Arch Linux instalado (base minimal)
- Usuário com **sudo**
- **Internet** (clone do repo + pacotes via `yay`)
- Não rode os scripts como root

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

Instala a stack nova, remove pacotes de `packages/obsolete.txt` (hyprland, foot, yazi, …) e aplica configs.

### Flags do `install.sh`

| Flag | Efeito |
|------|--------|
| *(sem flags)* | Pacotes core + `apply.sh` + Ly + `chsh` para zsh + `doctor.sh` |
| `--extras` | Instala também `packages/extras.txt` |
| `--minimal` | Só core; **não** altera shell padrão (`chsh`) |

---

## Primeiro boot

1. Reinicie após o `install.sh` / `migrate-stack.sh`
2. O **Ly** abre no TTY1 (`ly@tty1.service`)
3. Faça login e selecione a sessão **`Niri (DMS)`**
4. **Não** use Hyprland (stack antiga)

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

Depois:

```bash
~/dotfiles/apply.sh
```

---

## Scripts

| Script | Função |
|--------|--------|
| `migrate-stack.sh` | Migra Hyprland → niri (pacotes + apply) |
| `apply.sh` | Symlinks + hooks pós-apply |
| `import.sh` | Copia configs locais → repo |
| `update.sh` | `git pull` + sync pacotes + apply + doctor |
| `install.sh` | Máquina nova |
| `doctor.sh` | Diagnóstico da stack niri |
| `tests/smoke.sh` | Smoke tests |

---

## Fluxo entre máquinas

```bash
# desta máquina
~/dotfiles/import.sh
cd ~/dotfiles && git add -A && git commit -m "sync" && git push

# outra máquina
~/dotfiles/update.sh
```

---

## Documentação

- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- [docs/KEYBINDS.md](docs/KEYBINDS.md)
- [packages/README.md](packages/README.md)

---

## O que é versionado

| Repo | Destino |
|------|---------|
| `config/niri/` | `~/.config/niri/` |
| `config/alacritty/` | `~/.config/alacritty/` |
| `config/scripts/` | `~/.config/scripts/` |
| `config/tmux/` | `~/.config/tmux/` |
| `config/DankMaterialShell/` | `~/.config/DankMaterialShell/` |
| `local-bin/` | `~/.local/bin/` |
| `systemd/user/` | `~/.config/systemd/user/` |
| `home/.zshrc`, etc. | `~/` |

**Não versionado:** wallpapers grandes, secrets, `user.conf`.
