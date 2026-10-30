# Avatar / imagem de perfil (DMS)

## Problema

O **AccountsService** recusa ícones **> 1 MiB**. O DMS manda a foto original → falha com:

```text
file '.../dms-profile-icon-...' is too large to be used as an icon
```

Além disso, o DMS atualiza o ícone do AccountsService mas **não** sincroniza `~/.face` (greeter / apps legados).

## Como funciona (Barista)

1. **`prepare-avatar.sh`** — redimensiona a imagem (≤ ~900 KB), grava `~/.face` / `.face.icon` / hypr avatar e chama `SetIconFile`.
2. **`patch-dms-avatar.sh`** — altera o `PortalService.qml` para chamar o prepare **antes** do `setIconFile`.
3. **`DMS_SHELL_DIR=~/.local/share/dms-ui`** — UI patchada persistente (`systemd/user/dms.service.d/avatar-patch.conf`).
4. **`avatar-sync.path`** — se AccountsService ou `~/.face` mudarem, roda `sync-avatar.sh`.

Fluxo na Settings do DMS: escolher foto → prepare → AccountsService → UI mostra o ícone.

## Instalação

Já entra no `apply.sh` / `post-apply`:

```bash
~/dotfiles/apply.sh
systemctl --user restart dms
```

Manual:

```bash
# 1) copiar UI embutida (DMS precisa ter rodado ao menos 1x)
~/dotfiles/config/scripts/refresh-dms-ui.sh
# 2) patch + drop-in
systemctl --user daemon-reload
systemctl --user restart dms
```

## Testar

```bash
# foto grande de propósito
dms ipc call profile setImage ~/Pictures/foto-grande.jpg
sleep 2
dms ipc call profile getImage
stat -c%s ~/.face /var/lib/AccountsService/icons/$USER
```

Ambos devem ficar **< 1048576** bytes.

## Bugs

| Sintoma | Fix |
|---------|-----|
| Notificação “too large” | Patch não ativo: `systemctl --user show dms -p Environment` deve ter `DMS_SHELL_DIR=…/dms-ui`. Rode `refresh-dms-ui.sh` + restart. |
| Avatar muda na sessão, greeter antigo | Greeter lê AccountsService e/ou `~/.face`. Rode `sync-avatar.sh`. Cache `/var/cache/dms-greeter` é do user `greeter` (precisa `g+w` ou ACL — opcional). |
| UI quebrada após `dms update` | `~/.config/scripts/refresh-dms-ui.sh` && `systemctl --user restart dms` |
| `getImage` aponta pra `/tmp/...` | Sem o patch, o DMS guarda o path original. Com o patch, volta pro IconFile do AccountsService. |

## Dependências

- `imagemagick` (`magick`) — resize
- `python-dbus` / `dbus-python` — SetIconFile
- `dms-shell` ≥ 1.6
