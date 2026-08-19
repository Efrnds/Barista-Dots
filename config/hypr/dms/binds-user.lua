-- User keybind overrides (loaded after DMS defaults)

local home = os.getenv("HOME") or ("/home/" .. (os.getenv("USER") or ""))
local scripts = home .. "/.config/hypr/scripts"
local editor = scripts .. "/launch_cursor.sh"
local browser = scripts .. "/toggle_zen_browser.sh"
local fileManager = "/usr/bin/foot -e yazi"
local terminal = scripts .. "/launch_terminal.sh"

-- Unbind DMS defaults that conflict with existing workflow
hl.unbind("SUPER + T")
hl.unbind("SUPER + V")
hl.unbind("SUPER + M")
hl.unbind("SUPER + SHIFT + N")
hl.unbind("SUPER + W")
hl.unbind("SUPER + SHIFT + W")
hl.unbind("SUPER + H")
hl.unbind("SUPER + L")
hl.unbind("SUPER + R")
hl.unbind("SUPER + P")
hl.unbind("SUPER + SHIFT + P")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + I")
hl.unbind("SUPER + comma")
hl.unbind("SUPER + Y")
-- SUPER+SHIFT+Slash: painel DMS de keybinds (mantido)

-- Shell / DMS panels (mapped from old iNiR binds)
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("dms ipc call powermenu toggle"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("dms ipc call control-center toggle"))
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("dms ipc call control-center toggle"))
hl.bind("SUPER + ALT + D", hl.dsp.exec_cmd("dms ipc call dash toggle"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("dms ipc call hypr toggleBinds"))
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("dms ipc call settings toggle"))
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("dms ipc call keybinds toggle hyprland"))

-- Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + C", hl.dsp.exec_cmd(editor))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

-- Wallpapers (DMS native)
hl.bind("SUPER + W", hl.dsp.exec_cmd("dms ipc call wallpaper next"))
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("dms ipc call dankdash wallpaper"))
hl.bind("SUPER + ALT + W", hl.dsp.exec_cmd("dms ipc call file browse wallpaper"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_wallpapers.sh"))
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_wallpapers.sh"))

-- Custom scripts / menus
hl.bind("SUPER + period", hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji.sh"))
hl.bind("SUPER + F1", hl.dsp.exec_cmd("~/.config/hypr/scripts/keybinds.sh"))
hl.bind("SUPER + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_locate.sh"))
hl.bind("SUPER + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_apps.sh"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/edit_configs.sh"))
hl.bind("SUPER + ALT + Y", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_vpn.sh"))
hl.bind("SUPER + I", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_network_info.sh"))
hl.bind("SUPER + ALT + U", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_audio.sh"))
hl.bind("SUPER + ALT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/menu_ssh.sh"))
hl.bind("SUPER + R", hl.dsp.exec_cmd("bash " .. home .. "/.config/hypr/scripts/rdp-server.sh"))

-- Scratchpads / toggles
hl.bind("SUPER + M", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_spotify.sh"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_superproductivity.sh"))

-- Session / lock
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + SHIFT + M", hl.dsp.exit())

-- Screenshots (keep existing workflow)
hl.unbind("Print")
hl.unbind("CTRL + Print")
hl.unbind("ALT + Print")
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | swappy -f -]]))
hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy && notify-send -u low -t 1500 "Print Screen" "Captura da área copiada para a área de transferência!"]]))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd([[grim ~/Pictures/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png && notify-send -u low -t 1500 "Print Screen" "Captura de tela inteira salva em Imagens/Screenshots!"]]))
hl.bind("CTRL + Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" ~/Pictures/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png && notify-send -u low -t 1500 "Print Screen" "Captura de área salva em Imagens/Screenshots!"]]))

-- Resize with SUPER + CTRL + arrows (from old config)
hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true })

-- Workspace 10 (DMS defaults stop at 9)
hl.bind("SUPER + 0", hl.dsp.focus({ workspace = "10" }))
hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = "10" }))

-- Lid switch
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("loginctl lock-session"), { locked = true })

-- Btop float
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd([[foot -o main.font="JetBrainsMono Nerd Font:size=9.5" --app-id=btop-float -e btop]]))
