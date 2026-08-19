#!/usr/bin/env python3
"""Per-app volume mixer via EWW picker."""
from __future__ import annotations

import json
import os
import subprocess
import sys

PICKER = os.path.expanduser("~/.config/hypr/scripts/picker.sh")


def run(cmd: str) -> str:
    return subprocess.check_output(cmd, shell=True, text=True)


def pick(prompt: str, lines: str) -> str:
    proc = subprocess.run(
        [PICKER, "-p", prompt],
        input=lines,
        text=True,
        stdout=subprocess.PIPE,
        check=False,
    )
    return proc.stdout.strip()


def main() -> None:
    try:
        inputs = json.loads(run("pactl -f json list sink-inputs"))
    except Exception:
        subprocess.run(["notify-send", "-u", "critical", "Volume Mixer", "Erro ao acessar o PulseAudio/PipeWire."])
        sys.exit(1)

    if isinstance(inputs, dict):
        inputs = [inputs]
    if not inputs:
        subprocess.run(["notify-send", "Volume Mixer", "Nenhum aplicativo reproduzindo áudio no momento."])
        sys.exit(0)

    options = []
    index_map = {}
    for item in inputs:
        idx = item.get("index")
        props = item.get("properties", {})
        app_name = props.get("application.name", props.get("media.name", f"Aplicativo {idx}"))
        if app_name == "Chromium input":
            app_name = "Navegador"
        vol_pct = "100%"
        for data in item.get("volume", {}).values():
            if isinstance(data, dict) and "value_percent" in data:
                vol_pct = data["value_percent"]
                break
        label = f"🔊 {app_name} (Volume atual: {vol_pct})"
        options.append(label)
        index_map[label] = (idx, app_name)

    choice = pick("🎛️ Mixer de Volume", "\n".join(options))
    if not choice or choice not in index_map:
        sys.exit(0)

    idx, app_name = index_map[choice]
    vol_choice = pick(
        f"Volume para {app_name}",
        "0% (Mutar)\n20%\n40%\n60%\n80%\n100% (Padrão)\n120% (Amplificado)",
    )
    if not vol_choice:
        sys.exit(0)

    try:
        vol_val = int(vol_choice.split()[0].replace("%", ""))
        subprocess.run(f"pactl set-sink-input-volume {idx} {vol_val}%", shell=True)
        subprocess.run(["notify-send", "-t", "1500", "Mixer de Volume", f"Volume de {app_name} definido para {vol_val}%"])
    except ValueError:
        subprocess.run(["notify-send", "-u", "critical", "Mixer de Volume", "Valor de volume inválido."])


if __name__ == "__main__":
    main()
