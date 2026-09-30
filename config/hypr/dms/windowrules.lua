-- DMS Window Rules — managed by DankMaterialShell
-- Do not edit manually; changes may be overwritten

-- DMS-RULE: id=dms_rule_0, name=
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })

-- DMS-RULE: id=dms_rule_1, name=
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })

-- DMS-RULE: id=dms_rule_2, name=
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })

-- DMS-RULE: id=dms_rule_3, name=
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })

-- DMS-RULE: id=dms_rule_4, name=
hl.window_rule({ match = { class = "^(thunar)$", title = "^(Progresso da Operação de Arquivo|File Operation Progress)$" }, float = true })

-- DMS-RULE: id=dms_rule_5, name=
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, float = true })

-- DMS-RULE: id=dms_rule_6, name=
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, workspace = "special:spotify" })

-- DMS-RULE: id=dms_rule_7, name=
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, float = true })

-- DMS-RULE: id=dms_rule_8, name=
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, workspace = "special:superproductivity" })

-- DMS-RULE: id=dms_rule_9, name=
hl.window_rule({ match = { class = "^(btop-float)$" }, float = true })

-- DMS-RULE: id=dms-floating-windows, name=DMS Floating Windows
hl.window_rule({ match = { class = "^com.danklinux.dms$" }, float = true })
