# Análise: boot + startup (referência)

Medido em 2026-10-28 nesta máquina (Lenovo). Números mudam com firmware/disco.

## Números

| Fase | Tempo | Notas |
|------|-------|--------|
| Firmware | **~7s** | Quiet/Fast Boot no BIOS corta isso |
| GRUB | ~0.6s | timeout 0 / hidden |
| Kernel | ~3.8s | ok |
| Userspace → graphical | ~3.9s | |
| **Total até graphical** | **~16s** | |

Pós-login até wallpaper DMS: tipicamente **~4s** (compositor vivo, tema ainda carregando).

## Mitigações no repo

- Plymouth barista + GRUB quiet → [BOOT-LOGIN.md](./BOOT-LOGIN.md)
- Autostarts mascarados (VBox, KDE Connect, etc.)
- Avatar / DMS UI patch → [AVATAR.md](./AVATAR.md)
- `scripts/fast-boot-system.sh` (sudo) — NM wait-online, cups socket, etc.

## O que NÃO some 100%

Handoff greeter Wayland ↔ sessão Wayland = flash DRM. Autologin reduz; greeter TTY também.
