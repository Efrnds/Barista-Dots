# ☕ Barista Dots

Dotfiles com **symlinks** para Arch Linux — mesma config em várias máquinas.

## Stack oficial

| Componente | Versão / nota |
|------------|---------------|
| **Arch Linux** | base minimal |
| **Hyprland** | 0.56 (Lua config) |
| **DMS** | DankMaterialShell |
| **Foot** | terminal + tmux |
| **tmux** | prefixo `Ctrl+b` |
| **fuzzel** | launcher (via DMS spotlight) |
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

### Flags do `install.sh`

| Flag | Efeito |
|------|--------|
| *(sem flags)* | Pacotes core + `apply.sh` + Ly + `chsh` para zsh + `doctor.sh` |
| `--extras` | Instala também `packages/extras.txt` (docker, tlp, ufw, etc.) |
| `--minimal` | Só core; **não** altera shell padrão (`chsh`) |

Exemplos:

```bash
./install.sh --extras          # stack completo + extras
./install.sh --minimal         # core sem trocar shell
```

---

## Primeiro boot

1. Reinicie após o `install.sh`
2. O **Ly** abre no TTY1 (`ly@tty1.service`)
3. Faça login e selecione a sessão **`Hyprland (DMS)`**
4. **Não** use `Hyprland`, `Hyprland (uwsm-managed)` nem `shell`

A sessão correta executa `/usr/bin/start-hyprland` (DMS + Hyprland).

---

## Keybinds essenciais

| Atalho | Ação |
|--------|------|
| `Super+T` | Terminal (Foot + tmux) |
| `Super+Space` | Launcher (DMS spotlight) |
| `Super+B` | Browser (zen-browser) |
| `Super+C` | Editor (Cursor) |
| `Super+E` | Gerenciador de arquivos (yazi no Foot) |
| `Super+Shift+C` | Toggle binds Hypr (liga/desliga atalhos) |
| `Super+Escape` | Powermenu DMS |

Lista completa: [docs/KEYBINDS.md](docs/KEYBINDS.md)

---

## Customizar

Edite **`~/.config/dotfiles/user.conf`** (criado no primeiro `apply.sh`, não versionado):

```bash
# Apps (Super+T/C/B/E)
TERMINAL_CMD="/usr/bin/foot"
TERMINAL_CLASS="foot"
BROWSER_CMD="zen-browser"
BROWSER_CLASS="zen"
FILE_MANAGER_CMD="yazi"
CURSOR_APP="${HOME}/Applications/cursor.AppImage"
```

Depois rode:

```bash
~/dotfiles/apply.sh
```

---

## Scripts

| Script | Função |
|--------|--------|
| `apply.sh` | Symlinks dotfiles → home + hooks pós-apply |
| `import.sh` | Copia configs locais → repo (antes de commit) |
| `update.sh` | `git pull` + `apply.sh` + session manager + `doctor.sh` |
| `install.sh` | Máquina nova: pacotes + apply + Ly |
| `setup.sh` | Clone + install (one-liner) |
| `doctor.sh` | Diagnóstico do stack (binários, Ly, Foot, binds) |
| `tests/smoke.sh` | Smoke tests pós install/apply (CI/local) |

---

## Fluxo entre máquinas

**Esta máquina → GitHub:**

```bash
~/dotfiles/import.sh
cd ~/dotfiles && git add -A && git commit -m "sync configs" && git push
```

**Outra máquina:**

```bash
~/dotfiles/update.sh
```

---

## Documentação

- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — fixes copy-paste (Ly, Foot, binds, sessão)
- [docs/KEYBINDS.md](docs/KEYBINDS.md) — atalhos Hyprland + tmux

---

## O que é versionado

| Repo | Destino |
|------|---------|
| `config/hypr/` | `~/.config/hypr/` |
| `config/foot/` | `~/.config/foot/` |
| `config/tmux/` | `~/.config/tmux/` |
| `config/DankMaterialShell/` | `~/.config/DankMaterialShell/` |
| `local-bin/` | `~/.local/bin/` |
| `systemd/user/` | `~/.config/systemd/user/` |
| `home/.zshrc`, etc. | `~/` |

**Não versionado:** wallpapers grandes, secrets, `~/.config/dotfiles/user.conf`, backups DMS.
