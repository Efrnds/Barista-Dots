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
| `update.sh` | `git pull` + `apply.sh` |
| `install.sh` | Máquina nova: pacotes + apply |
| `setup.sh` | Clone + install (one-liner) |

---

## Pós-apply automático

- `chmod +x` nos scripts hypr
- `systemctl --user enable` units (ex: sync Foot ↔ DMS)
- `hyprctl reload` se sessão Wayland ativa
