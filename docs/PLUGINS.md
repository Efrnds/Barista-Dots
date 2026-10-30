# Plugins DMS (Barista)

Plugins custom em `dms-plugins/`, linkados para `~/.config/DankMaterialShell/plugins/` no `apply.sh` / `post-apply`.

## Lista

| Plugin | ID | O que faz |
|--------|-----|-----------|
| **Barista Hub** | `baristaHub` | Uma pill: Freela + OBS + RTK |
| **Freela Timer** | `freelaTimer` | Timer por projeto + invoice |
| **OBS Rec** | `obsRec` | Status de gravação/stream |
| **RTK Status** | `rtkStatus` | Projetos sem RTK + savings |
| **LAN IP** | `lanIp` | IP local; clique copia |

Ative na barra: DMS → Settings → Plugins / Bar widgets.

## Idioma (i18n)

Strings de UI usam **inglês como fonte** + `I18n.trFor("<pluginId>", "…")`.

Traduções ficam em:

```
dms-plugins/<pluginId>/translations/<lang>.json
```

Ex.: `translations/pt.json` para português. O DMS escolhe o idioma pelo locale do usuário (`LANG` / settings do DMS).

Formato (igual ao ExampleEmojiPlugin do DMS):

```json
{
  "Stop": { "Stop": "Parar" },
  "Activating RTK in %1…": { "Activating RTK in %1…": "Ativando RTK em %1…" }
}
```

Para adicionar outro idioma: copie `pt.json` → `es.json` (etc.) e traduza os valores.

## Helpers

| Script | Plugin |
|--------|--------|
| `~/.config/scripts/freela-timer.sh` | freela / hub |
| `~/.config/scripts/obs-rec-status.py` | obs / hub |
| `~/.local/bin/rtk-bar` | rtk / hub |

## Bugs comuns

**Texto ainda em PT/EN errado**  
- Confirme `translations/pt.json` no plugin.  
- Reinicie o DMS: `systemctl --user restart dms`.  
- Locale: `echo $LANG` e idioma no DMS Settings.

**Plugin não aparece**  
```bash
ls -la ~/.config/DankMaterialShell/plugins/
~/dotfiles/apply.sh
systemctl --user restart dms
```

**Hub/RTK “Target not found” / helper some**  
PATH do DMS é curto — os widgets usam caminhos absolutos (`~/.local/bin/rtk-bar`). Garanta que o binário existe.
