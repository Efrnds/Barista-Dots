# Pacotes

| Arquivo | Uso |
|---------|-----|
| `core.txt` | Stack oficial: **niri + DMS + Alacritty + Thunar** |
| `extras.txt` | Opcionais (docker, games, etc.) |
| `obsolete.txt` | Stack antiga (Hyprland/Foot/Yazi) — removida por `migrate-stack.sh` / `update.sh` |

Atualize `extras.txt` com `~/dotfiles/import.sh` antes de commitar (depois de limpar obsolete).

```bash
# Máquina nova
./install.sh --extras

# Migrar de Hyprland → niri
./migrate-stack.sh --yes

# Atualizar no dia a dia
./update.sh
```
