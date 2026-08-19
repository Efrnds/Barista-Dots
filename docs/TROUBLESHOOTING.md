# Troubleshooting — Barista Dots

Fixes copy-paste para problemas comuns no stack Arch + Hyprland + DMS + Foot + Ly.

---

## Ly: tela preta (sem login)

**Causa:** `full_color = false` no Ly, ou getty desabilitado manualmente.

**Fix:**

```bash
# Reaplicar config Ly do repo (full_color=true, sessões custom)
~/dotfiles/hooks/setup-session.sh

# Confirmar full_color
grep full_color /etc/ly/config.ini
# deve mostrar: full_color = true

# Ly no tty1 (Ly 1.4+ — não existe mais ly.service)
sudo systemctl enable ly@tty1.service
sudo systemctl enable getty@tty1.service   # fallback se Ly falhar
sudo systemctl restart ly@tty1.service
```

**Importante:** não desabilite `getty@tty1` manualmente. O `ly@tty1.service` já conflita com getty quando ativo; se Ly falhar e getty estiver off, o TTY fica preto sem login.

---

## Ly: "failed to initialize user"

**Causas comuns:** shell inválido em `/etc/passwd`, sessão errada, `start-hyprland` ausente.

**Fix:**

```bash
# Verificar shell do usuário
getent passwd "$USER" | cut -d: -f7
# deve ser um binário existente, ex: /usr/bin/zsh

# Corrigir automaticamente (install/validate-login)
~/dotfiles/hooks/validate-login.sh

# Corrigir manualmente se necessário
sudo chsh -s /usr/bin/zsh "$USER"

# Verificar sessão Hyprland
command -v start-hyprland
/usr/bin/start-hyprland   # teste no TTY (Ctrl+Alt+F2)

# Logs Ly
sudo tail -30 /var/log/ly.log
```

---

## Foot não abre (Super+T sem efeito)

**Causas:** bug no `launch_or_focus.sh`, binds DMS desligados (`openBinds`), shell path inválido no `foot.ini`.

**Fix:**

```bash
# Reaplicar configs e permissões
~/dotfiles/apply.sh
chmod +x ~/.config/hypr/scripts/*.sh

# Verificar shell do Foot (deve ser path absoluto executável)
grep '^shell=' ~/.config/foot/foot.ini
# ex: shell=/home/SEU_USER/.local/bin/foot-tmux.sh
test -x "$(grep '^shell=' ~/.config/foot/foot.ini | cut -d= -f2-)"

# Reativar binds DMS
dms ipc call hypr openBinds

# Testar launch manual
~/.config/hypr/scripts/launch_terminal.sh
```

Se `launch_or_focus` falhar ao focar janela existente, o script cai no `exec` do comando de launch — confirme que `TERMINAL_CMD` e `TERMINAL_CLASS` em `~/.config/dotfiles/user.conf` batem com o Foot.

---

## Super+T não funciona (outros atalhos também)

**Causa mais comum:** binds Hypr **desligados** via DMS (`Super+Shift+C`).

**Fix:**

```bash
# Reativar binds
dms ipc call hypr openBinds

# Ou pressione Super+Shift+C na sessão

# Diagnóstico completo
~/dotfiles/doctor.sh
```

O `doctor.sh` verifica se `Super+T` está registrado e se `openBinds` responde com success.

---

## Hyprland via Ly: sessão errada

**Sintoma:** login ok mas Hyprland não sobe, ou sobe sem DMS.

**Causa:** Ly listando `/usr/bin/Hyprland` direto (bug com `.desktop` chamado `Hyprland`) ou sessão uwsm.

**Fix:**

```bash
# Reaplicar sessão custom e config Ly
~/dotfiles/hooks/setup-session.sh

# No Ly, escolher EXATAMENTE:
#   Hyprland (DMS)
# NÃO usar: Hyprland | Hyprland (uwsm-managed) | shell
```

A sessão correta executa `/usr/bin/start-hyprland` (`/etc/ly/custom-sessions/hyprland.desktop`).

Após `git pull` em outra máquina:

```bash
~/dotfiles/update.sh
# reinicie ou relogue; selecione Hyprland (DMS)
```

---

## doctor.sh

Relatório de saúde do stack. Rode após install, apply ou quando algo quebrar.

```bash
~/dotfiles/doctor.sh
```

Verifica:

- Binários: `hyprland`, `foot`, `tmux`, `dms`, `fuzzel`, `ly`, `start-hyprland`
- Symlinks e `hyprland.lua`, `foot.ini`, `user.conf`
- Shell path do Foot
- Ly: `ly@tty1.service`, `full_color=true`
- Scripts executáveis: `launch_terminal.sh`, `launch_or_focus.sh`, etc.
- Em sessão Wayland: `Super+T` nos binds, `dms ipc call hypr openBinds`

Exit code `0` = OK (avisos permitidos); `1` = erros encontrados.

Sugestões automáticas no final:

```bash
~/dotfiles/apply.sh
~/dotfiles/hooks/setup-session.sh
dms ipc call hypr openBinds
```

---

## smoke.sh

Smoke tests rápidos (útil em CI ou pós-install). Não precisa de GUI completa.

```bash
~/dotfiles/tests/smoke.sh
```

Verifica presença de binários, configs linkadas, `foot-tmux.sh`, `user.conf`, `doctor.sh`, Ly enabled (se aplicável), e ausência de paths hardcoded `/home/eduardo` no repo.

Exit code `0` = smoke OK; `1` = falhas listadas.

---

## Atualizar após mudanças no repo

```bash
~/dotfiles/update.sh
```

Equivale a: `git pull` → `apply.sh` → `setup-session.sh` → `doctor.sh`.
