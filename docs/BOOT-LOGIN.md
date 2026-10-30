# Boot, login e silêncio (Plymouth / greetd)

## Stack atual

| Fase | Componente |
|------|------------|
| Splash | **Plymouth** tema `barista` (logo + barra estilo fill) |
| Login | **greetd** + **dms-greeter** (ou autologin → niri) |
| Sessão | **niri** + **dms** (`niri-session-fast` quando aplicável) |
| Lock | DMS lock + **fprintd** (PAM), não no boot |

`session.conf`:

```bash
SESSION_MANAGER=dms-greeter   # ou ly | auto
```

## Instalação (precisa sudo)

### Plymouth barista

```bash
~/dotfiles/plymouth/install-barista-plymouth.sh
# ou polish completo (GRUB quiet + hook):
~/dotfiles/plymouth/apply-boot-polish.sh
```

### Shutdown silencioso

```bash
~/dotfiles/scripts/apply-silent-shutdown.sh
```

### Boot mais rápido (opcional)

```bash
~/dotfiles/scripts/fast-boot-system.sh
```

### greetd / greeter

```bash
~/dotfiles/hooks/setup-session.sh
# configs de referência: greetd/config.toml , greetd/*.pam
```

Fingerprint: PAM OR (senha **ou** digital) em greetd/lock — ver `greetd/greetd.pam` e docs do `python-validity` / `fprintd`.

## Por que ainda pode haver “tela preta”

Com **greeter Wayland** + **sessão Wayland** (dois compositors) há handoff de DRM. Mitigações:

- Autologin (`initial_session` no greetd) → niri direto (menos flash)
- Evitar awww/early-wallpaper competindo com o DMS
- `niri-session-fast` + `source_profile=false` (sem spam TTY laranja)

## Bugs

| Sintoma | Fix |
|---------|-----|
| Texto laranja no boot | GRUB/`kernel` quiet + plymouth; `source_profile=false` no greetd; não rodar fastfetch no `.zprofile` de login |
| Dual black após login | Dois niri (greeter+user). Prefira autologin ou greeter TTY |
| Digital não aparece | `fprintd` + PAM; udev validity sem autosuspend; reboot após udev |
| Plymouth stuck / logo feio | Reinstalar tema + `mkinitcpio -P` + `grub-mkconfig` |
| Shutdown com spam systemd | `apply-silent-shutdown.sh` + `ShowStatus=no` |

## Análise de tempos

Ver [boot-startup-analysis.md](./boot-startup-analysis.md) (números de referência; firmware Lenovo costuma ser a maior fatia).
