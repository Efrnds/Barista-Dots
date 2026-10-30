#!/usr/bin/env bash
# Patch DMS PortalService so profile images are resized before AccountsService (1 MiB limit).
# Prefers persistent UI at ~/.local/share/dms-ui (used via DMS_SHELL_DIR).
set -euo pipefail

MARKER="DMS_AVATAR_PREPARE_PATCH"
script="$HOME/.config/scripts/prepare-avatar.sh"
[[ -x "$script" ]] || script="$HOME/dotfiles/config/scripts/prepare-avatar.sh"
[[ -x "$script" ]] || exit 0

shopt -s nullglob
targets=()
if [[ -f "$HOME/.local/share/dms-ui/Services/PortalService.qml" ]]; then
  targets+=("$HOME/.local/share/dms-ui/Services/PortalService.qml")
fi
# Also patch any live extract (chmod may be needed; often read-only)
for f in /run/user/"$(id -u)"/danklinux-shell/*/Services/PortalService.qml; do
  targets+=("$f")
done
[[ ${#targets[@]} -eq 0 ]] && exit 0

python3 - "$script" "${targets[@]}" <<'PY'
import pathlib, sys

script = pathlib.Path(sys.argv[1]).resolve()
marker = "DMS_AVATAR_PREPARE_PATCH"

# Replacement for setSystemProfileImage + helper Process (injected once)
inject = f'''
    // {marker}
    function setSystemProfileImage(imagePath) {{
        if (!accountsServiceAvailable || !freedeskAvailable)
            return;
        if (imagePath && imagePath !== "") {{
            pendingProfileImage = imagePath;
            prepareAvatarProcess.command = ["bash", "{script}", imagePath];
            prepareAvatarProcess.running = true;
            return;
        }}
        pendingProfileImage = "";
        DMSService.sendRequest("freedesktop.accounts.setIconFile", {{
            "path": ""
        }}, response => {{
            if (response.error) {{
                log.warn("Failed to set icon file:", response.error);
                Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "DMS", "-i", "error", I18n.tr("Profile Image Error"), I18n.tr("Failed to clear profile image")]);
            }} else {{
                profileImage = "";
                Qt.callLater(() => getSystemProfileImage());
            }}
        }});
    }}

    Process {{
        id: prepareAvatarProcess
        command: []
        running: false
        stdout: StdioCollector {{
            onStreamFinished: {{
                const prepared = text.trim().split("\\n").filter(l => l.length > 0).pop() || "";
                if (prepared && prepared.startsWith("/")) {{
                    root.profileImage = prepared;
                    root.pendingProfileImage = "";
                    Qt.callLater(() => root.getSystemProfileImage());
                }}
            }}
        }}
        stderr: StdioCollector {{
            onStreamFinished: {{
                if (text.trim().length > 0)
                    root.log.warn("prepare-avatar:", text.trim());
            }}
        }}
        onExited: exitCode => {{
            if (exitCode !== 0) {{
                root.pendingProfileImage = "";
                Quickshell.execDetached(["notify-send", "-u", "normal", "-a", "DMS", "-i", "error", I18n.tr("Profile Image Error"), I18n.tr("Profile image is too large. Please use a smaller image.")]);
            }}
        }}
    }}
'''

# Also fix getSystemProfileImage to always refresh from AccountsService
old_get_snip = '''                if (iconFile && iconFile !== "" && iconFile !== "/var/lib/AccountsService/icons/") {
                    systemProfileImage = iconFile;
                    if (!profileImage || profileImage === "") {
                        profileImage = iconFile;
                    }
                }'''

new_get_snip = '''                if (iconFile && iconFile !== "" && iconFile !== "/var/lib/AccountsService/icons/") {
                    systemProfileImage = iconFile;
                    profileImage = iconFile;
                }'''

for path in sys.argv[2:]:
    p = pathlib.Path(path)
    try:
        p.chmod(p.stat().st_mode | 0o200)
    except Exception:
        pass
    text = p.read_text()
    if marker in text and "prepareAvatarProcess" in text:
        # still fix getSystem if needed
        if old_get_snip in text:
            text = text.replace(old_get_snip, new_get_snip)
            p.write_text(text)
            print(f"updated getSystem: {p}")
        else:
            print(f"already patched: {p}")
        continue

    # Remove original setSystemProfileImage function body (from function line through closing brace of function)
    start = text.find("    function setSystemProfileImage(imagePath) {")
    if start < 0:
        print(f"no setSystemProfileImage in {p}", file=sys.stderr)
        continue

    # find matching closing brace for the function
    i = text.find("{", start)
    depth = 0
    end = None
    for j in range(i, len(text)):
        if text[j] == "{":
            depth += 1
        elif text[j] == "}":
            depth -= 1
            if depth == 0:
                end = j + 1
                break
    if end is None:
        print(f"parse fail {p}", file=sys.stderr)
        continue

    text = text[:start] + inject + text[end:]
    if old_get_snip in text:
        text = text.replace(old_get_snip, new_get_snip)

    # Ensure Quickshell.Io is imported (Process)
    if "import Quickshell.Io" not in text:
        text = text.replace("import Quickshell\n", "import Quickshell\nimport Quickshell.Io\n")

    p.write_text(text)
    print(f"patched: {p}")
PY
