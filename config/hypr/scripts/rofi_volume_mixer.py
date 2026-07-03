#!/usr/bin/env python3
import subprocess
import json
import sys

# Script Python + Rofi para controle individual de volume de aplicativos (Mixer)

def run_cmd(cmd):
    return subprocess.check_output(cmd, shell=True).decode('utf-8')

def main():
    # 1. Obtém a lista de fontes de áudio ativas em JSON
    try:
        raw_json = run_cmd("pactl -f json list sink-inputs")
        inputs = json.loads(raw_json)
    except Exception as e:
        subprocess.run(["notify-send", "-u", "critical", "Volume Mixer", "Erro ao acessar o PulseAudio/PipeWire."])
        sys.exit(1)

    # Se não houver apps reproduzindo som
    if not inputs:
        subprocess.run(["notify-send", "Volume Mixer", "Nenhum aplicativo reproduzindo áudio no momento."])
        sys.exit(0)

    # 2. Constrói as opções do Rofi
    options = []
    index_map = {}
    
    # Se inputs for um dicionário único (pactl retorna dict se houver só um, ou list se houver múltiplos)
    if isinstance(inputs, dict):
        inputs = [inputs]

    for item in inputs:
        idx = item.get("index")
        props = item.get("properties", {})
        app_name = props.get("application.name", props.get("media.name", f"Aplicativo {idx}"))
        
        # Filtra nomes genéricos comuns para melhor visualização
        if app_name == "Chromium input":
            app_name = "Navegador"

        # Pega a porcentagem de volume
        vol_info = item.get("volume", {})
        vol_pct = "100%"
        for channel, data in vol_info.items():
            if isinstance(data, dict) and "value_percent" in data:
                vol_pct = data["value_percent"]
                break
        
        label = f"🔊 {app_name} (Volume atual: {vol_pct})"
        options.append(label)
        index_map[label] = (idx, app_name)

    # 3. Rofi para selecionar o aplicativo
    rofi_input = "\n".join(options)
    rofi_proc = subprocess.Popen(
        ["rofi", "-dmenu", "-p", "🎛️ Mixer de Volume", "-i", "-theme-str", "window {width: 32%;} listview {lines: 6;}"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )
    stdout, _ = rofi_proc.communicate(input=rofi_input.encode('utf-8'))
    choice = stdout.decode('utf-8').strip()

    if not choice or choice not in index_map:
        sys.exit(0)

    idx, app_name = index_map[choice]

    # 4. Rofi para escolher o volume
    vol_options = "0% (Mutar)\n20%\n40%\n60%\n80%\n100% (Padrão)\n120% (Amplificado)"
    vol_proc = subprocess.Popen(
        ["rofi", "-dmenu", "-p", f"Volume para {app_name}", "-i", "-theme-str", "window {width: 25%;} listview {lines: 7;}"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE
    )
    vol_stdout, _ = vol_proc.communicate(input=vol_options.encode('utf-8'))
    vol_choice = vol_stdout.decode('utf-8').strip()

    if not vol_choice:
        sys.exit(0)

    # Extrai o valor do volume
    vol_str = vol_choice.split()[0].replace("%", "")
    try:
        vol_val = int(vol_str)
        # Define o volume do stream
        subprocess.run(f"pactl set-sink-input-volume {idx} {vol_val}%", shell=True)
        # Feedback visual
        subprocess.run(["notify-send", "-t", "1500", "Mixer de Volume", f"Volume de {app_name} definido para {vol_val}%"])
    except ValueError:
        subprocess.run(["notify-send", "-u", "critical", "Mixer de Volume", "Valor de volume inválido."])

if __name__ == "__main__":
    main()
