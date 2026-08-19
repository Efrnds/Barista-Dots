# Fallback Noctalia — só usar se DMS falhar

## Quando acionar
- DMS não sobe após `dms run`
- Crash repetido ou menus sem resposta após debug

## Passos
1. Parar DMS:
   ```bash
   dms kill
   pkill -f quickshell
   ```
2. (Opcional) Restaurar Hyprland antigo:
   ```bash
   cp ~/.config/hypr/.dms-backups/<timestamp>/hyprland.conf ~/.config/hypr/hyprland.conf
   rm ~/.config/hypr/hyprland.lua
   ```
3. Instalar deps Noctalia:
   ```bash
   paru -S --needed noctalia-qs brightnessctl imagemagick python git
   ```
4. Instalar shell:
   ```bash
   mkdir -p ~/.config/quickshell/noctalia-shell
   curl -sL https://github.com/noctalia-dev/noctalia/releases/latest/download/noctalia-latest.tar.gz \
     | tar -xz --strip-components=1 -C ~/.config/quickshell/noctalia-shell
   ```
5. Autostart em hyprland:
   ```
   exec-once = qs --no-duplicate -p ~/.config/quickshell/noctalia-shell
   ```
6. Docs: https://docs.noctalia.dev/noctalia-shell/getting-started/installation/

## Backups desta migração
- Pré-migração: ~/.cache/shell-migration-20260819-134411
- iNiR arquivado: ~/.cache/shell-migration-archive-20260819-134721
