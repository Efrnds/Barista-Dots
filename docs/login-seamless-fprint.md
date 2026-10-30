# Login + fingerprint (resumo)

Ver o guia completo: **[BOOT-LOGIN.md](./BOOT-LOGIN.md)**.

- **Boot:** pode usar autologin → niri (menos tela preta)
- **Digital:** no lock (`Super+L`), e no greeter se PAM estiver configurado
- **Logout:** dms-greeter

Não dá para ter greeter Wayland com digital **e** zero flash no handoff DRM — escolha o trade-off no `greetd/config.toml`.
