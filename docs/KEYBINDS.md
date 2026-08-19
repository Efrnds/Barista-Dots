# Keybinds — Barista Dots

Atalhos do stack **Hyprland 0.56 + DMS**, com overrides em `config/hypr/dms/binds-user.lua` (carregado **depois** dos defaults DMS em `binds.lua`).

**Toggle binds:** `Super+Shift+C` — desliga/liga atalhos Hypr via DMS (`toggleBinds`). Se nada responder, rode `dms ipc call hypr openBinds`.

---

## Essenciais (user)

| Atalho | Ação |
|--------|------|
| `Super+T` | Terminal (`launch_terminal.sh` → Foot + tmux) |
| `Super+Space` | Launcher DMS spotlight |
| `Super+B` | Browser (`toggle_zen_browser.sh`) |
| `Super+C` | Editor (`launch_cursor.sh`) |
| `Super+E` | yazi no Foot |
| `Super+Escape` | Powermenu DMS |
| `Super+Shift+C` | Toggle binds Hypr |

---

## DMS / painéis (user)

| Atalho | Ação |
|--------|------|
| `Super+A` | Control center |
| `Super+Alt+V` | Control center |
| `Super+Alt+D` | Dash DMS |
| `Super+Shift+P` | Settings DMS |

---

## Janelas (user)

| Atalho | Ação |
|--------|------|
| `Super+V` | Toggle float |
| `Super+Ctrl+←/→/↑/↓` | Redimensionar janela (repeat) |

---

## Wallpapers (user)

| Atalho | Ação |
|--------|------|
| `Super+W` | Próximo wallpaper |
| `Super+Shift+W` | Dash wallpaper |
| `Super+Alt+W` | Browse wallpaper |
| `Super+Ctrl+W` | Menu wallpapers |
| `Super+Shift+T` | Menu wallpapers |

---

## Menus e scripts (user)

| Atalho | Ação |
|--------|------|
| `Super+.` | Emoji picker |
| `Super+F1` | Cheat-sheet Hypr + tmux (picker) |
| `Super+S` | Localizar arquivo |
| `Super+G` | Menu apps |
| `Super+Shift+E` | Editar configs |
| `Super+Alt+Y` | Menu VPN |
| `Super+I` | Info de rede |
| `Super+Alt+U` | Menu áudio |
| `Super+Alt+S` | Menu SSH |
| `Super+R` | RDP server |

---

## Apps / scratchpads (user)

| Atalho | Ação |
|--------|------|
| `Super+M` | Toggle Spotify |
| `Super+P` | Toggle Super Productivity |

---

## Sessão / lock (user)

| Atalho | Ação |
|--------|------|
| `Super+L` | Lock (`loginctl lock-session`) |
| `Super+Shift+M` | Sair da sessão |
| `Lid Switch (on)` | Lock (locked bind) |

---

## Screenshots (user)

| Atalho | Ação |
|--------|------|
| `Super+Shift+S` | Área → swappy |
| `Print` | Área → clipboard |
| `Shift+Print` | Tela inteira → arquivo |
| `Ctrl+Print` | Área → arquivo |

---

## Workspaces (user + DMS)

| Atalho | Ação |
|--------|------|
| `Super+0` | Workspace 10 (user) |
| `Super+Shift+0` | Mover janela → workspace 10 (user) |
| `Super+1` … `Super+9` | Focar workspace (DMS) |
| `Super+Shift+1` … `Super+Shift+9` | Mover janela (DMS) |
| `Super+Page Up/Down` | Workspace anterior/próximo (DMS) |
| `Super+U` / `Super+I` | Workspace e+1 / e-1 (DMS) |

---

## Utilitários (user)

| Atalho | Ação |
|--------|------|
| `Ctrl+Shift+Escape` | btop float (Foot) |

---

## DMS defaults (ainda ativos)

Estes vêm de `binds.lua` e **não** foram substituídos em `binds-user.lua`:

| Atalho | Ação |
|--------|------|
| `Alt+Space` | Spotlight bar |
| `Super+N` | Notificações |
| `Super+Tab` / `Super+O` | Overview |
| `Super+Q` | Fechar janela |
| `Super+F` | Maximize toggle |
| `Super+Shift+F` | Fullscreen toggle |
| `Super+←/↓/↑/→` | Focar direção |
| `Super+Shift+←/↓/↑/→` | Mover janela |
| `Super+Ctrl+←/→` | Monitor anterior/próximo |
| `Super+Alt+L` | Lock DMS |
| `XF86Audio*` | Volume / mute / mídia (DMS) |
| `XF86MonBrightness*` | Brilho (DMS) |

| `Super+Shift+/` | Painel DMS de keybinds |

---

## tmux (prefixo `Ctrl+b`)

Prefixo padrão: **`Ctrl+b`**. Ajuda: `prefix + ?`.

| Atalho | Ação |
|--------|------|
| `Ctrl+b` `|` | Split horizontal (cwd atual) |
| `Ctrl+b` `-` | Split vertical (cwd atual) |
| `Ctrl+b` `h/j/k/l` | Navegar panes (vim) |
| `Ctrl+b` `r` | Recarregar `tmux.conf` |

Mouse habilitado. Terminal: `foot` com RGB.

Para trocar prefixo para `Ctrl+a`, descomente as linhas em `config/tmux/tmux.conf`.

---

## Customizar

- **Hypr:** edite `config/hypr/dms/binds-user.lua` no repo (ou importe com `import.sh`)
- **Apps (Super+T/C/B/E):** `~/.config/dotfiles/user.conf` + `apply.sh`
- **tmux:** `config/tmux/tmux.conf`
