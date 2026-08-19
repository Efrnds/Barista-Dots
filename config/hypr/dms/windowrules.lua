-- Custom window rules migrated from previous hyprland.conf

-- Browser: evita dezenas de janelas minúsculas no dwindle ao apertar Super+B várias vezes
hl.window_rule({ match = { class = "^(zen)$" }, tile = false })
hl.window_rule({ match = { class = "^(zen)$" }, size = "85% 85%" })
hl.window_rule({ match = { class = "^(zen)$" }, center = true })

hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ match = { class = "^(thunar)$", title = "^(Progresso da Operação de Arquivo|File Operation Progress)$" }, float = true })

-- Spotify scratchpad
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, float = true })
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, workspace = "special:spotify" })
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, size = "85% 85%" })
hl.window_rule({ match = { class = "^(spotify|Spotify)$" }, center = true })

-- Super Productivity scratchpad
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, float = true })
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, workspace = "special:superproductivity" })
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, size = "85% 85%" })
hl.window_rule({ match = { class = "^([Ss]uper[ -]?[Pp]roductivity)$" }, center = true })

-- Btop float
hl.window_rule({ match = { class = "^(btop-float)$" }, float = true })
hl.window_rule({ match = { class = "^(btop-float)$" }, size = "90% 80%" })
hl.window_rule({ match = { class = "^(btop-float)$" }, center = true })

-- Gamescope / Skyrim fullscreen fixes
hl.window_rule({ match = { class = "^(gamescope)$" }, float = false })
hl.window_rule({ match = { class = "^(gamescope)$" }, fullscreen = false })
hl.window_rule({ match = { class = "^(steam_app_489830)$" }, fullscreen = false })
hl.window_rule({ match = { class = "^(steam_app_3791709894)$", title = "(?i).*(skyrim|skse).*" }, fullscreen = false })
hl.window_rule({ match = { title = "(?i)^skyrim special edition$" }, fullscreen = false })
hl.window_rule({ match = { title = "(?i)^gamescope$" }, fullscreen = false })
