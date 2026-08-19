# ☕ Barista Dots (Arch + Hyprland + DMS)

Dotfiles com **symlinks**, pensados para manter a mesma config em várias máquinas.

Stack atual: **Hyprland 0.56 (Lua)** · **DankMaterialShell** · **Foot + tmux** · **fuzzel**

---

## Máquina nova (do zero)

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Efrnds/Barista-Dots/main/setup.sh)"
```

Ou manual:

```bash
git clone https://github.com/Efrnds/Barista-Dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

---

## Máquina que já tem o repo (atualizar após pull)

```bash
~/dotfiles/update.sh
```

Isso faz `git pull` + `./apply.sh` (symlinks + hooks).

Também roda automaticamente após `git pull` se você já executou `./apply.sh` uma vez (hooks `post-merge` / `post-checkout`).

---

## Fluxo de trabalho (esta máquina → GitHub)

1. Fez alterações em `~/.config/...`
2. Importa pro repo:

```bash
~/dotfiles/import.sh
cd ~/dotfiles
git diff
git add -A && git commit -m "sync configs"
git push
```

3. Na outra máquina:

```bash
~/dotfiles/update.sh
```

---

## O que é versionado

| Caminho no repo | Vai para |
|-----------------|----------|
| `config/hypr/` | `~/.config/hypr/` |
| `config/foot/` | `~/.config/foot/` |
| `config/tmux/` | `~/.config/tmux/` |
| `config/DankMaterialShell/` | `~/.config/DankMaterialShell/` |
| `config/nvim/`, `yazi/`, `btop/`, etc. | `~/.config/...` |
| `local-bin/` | `~/.local/bin/` |
| `systemd/user/` | `~/.config/systemd/user/` |
| `home/.zshrc`, etc. | `~/` |
| `packages.txt` | lista pacman -Qqe (via import) |

**Não versionado** (`.gitignore`): wallpapers grandes, secrets, backups DMS.

---

## Scripts

| Script | Função |
|--------|--------|
| `apply.sh` | Symlinks dotfiles → home + post-apply |
| `import.sh` | Copia configs atuais → repo (antes do commit) |
| `update.sh` | `git pull` + `apply.sh` + session manager (ly) |
| `install.sh` | Máquina nova: pacotes + apply |
| `setup.sh` | Clone + install (one-liner) |

---

## Session manager (Ly)

O Ly 1.4+ usa `ly@tty1.service` (não existe mais `ly.service`). O script `hooks/setup-session.sh` configura isso automaticamente no `install.sh` e no `update.sh`.

Config em `session.conf`:
```bash
SESSION_MANAGER=ly      # ou auto | dms-greeter
LY_TTY=tty1
```

Seu `/etc/ly/config.ini` customizado fica versionado em `etc/ly/config.ini` e é reaplicado no setup.

### Ly na outra máquina — "failed to initialize user"

Causas comuns e o que o repo corrige:

1. **Shell inválido** — `install.sh` instala `zsh` antes do `chsh`; `hooks/validate-login.sh` corrige se `/etc/passwd` apontar pra shell inexistente.
2. **Ly rodando `/usr/bin/Hyprland` em vez da sessão** — bug conhecido quando o `.desktop` se chama `Hyprland`. Fix: Ly só lista `/etc/ly/custom-sessions/` com sessão **`Hyprland (DMS)`** (`start-hyprland`).
3. **Não use** `Hyprland (uwsm-managed)` nem `shell` no Ly — escondidos na config.

Na outra máquina, depois do pull:
```bash
~/dotfiles/update.sh
# no Ly, escolha sessão: Hyprland (DMS)
```

Se ainda falhar, no TTY (Ctrl+Alt+F2):
```bash
getent passwd $USER    # shell existe?
/usr/bin/start-hyprland   # hyprland sobe?
sudo tail -30 /var/log/ly.log
```

- `chmod +x` nos scripts hypr
- `systemctl --user enable` units (ex: sync Foot ↔ DMS)
- `hyprctl reload` se sessão Wayland ativa
