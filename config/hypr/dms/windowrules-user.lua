-- User window rules (loaded after DMS defaults)

-- SSH terminals from Super+Alt+S (menu_ssh.sh)
hl.window_rule({ match = { class = "^ssh-float$" }, float = true })
