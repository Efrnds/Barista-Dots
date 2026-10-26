import re

config_path = '/etc/ly/config.ini'

try:
    with open(config_path, 'r') as f:
        content = f.read()

    # Substituições para aplicar o tema Lavender Dream e fogo roxo/lilás no Ly
    replacements = {
        r'^#?\s*animation\s*=\s*.*': 'animation = doom',
        r'^#?\s*bg\s*=\s*.*': 'bg = 0x00424874',                    # Background Slate-Blue (#424874)
        r'^#?\s*fg\s*=\s*.*': 'fg = 0x00F4EEFF',                    # Foreground Lilac-White (#F4EEFF)
        r'^#?\s*border_fg\s*=\s*.*': 'border_fg = 0x00A6B1E1',      # Borda Lilac-Blue (#A6B1E1)
        r'^#?\s*asterisk\s*=\s*.*': 'asterisk = 0x2022',            # Máscara de senha: bolinha (bullet)
        r'^#?\s*blank_box\s*=\s*.*': 'blank_box = false',           # Caixa transparente para ver a animação atrás
        r'^#?\s*clock\s*=\s*.*': 'clock = %d/%m/%Y %H:%M',          # Relógio ativo
        r'^#?\s*doom_top_color\s*=\s*.*': 'doom_top_color = 0x00424874',        # Fogo roxo escuro no topo
        r'^#?\s*doom_middle_color\s*=\s*.*': 'doom_middle_color = 0x00A6B1E1',  # Fogo lilás no meio
        r'^#?\s*doom_bottom_color\s*=\s*.*': 'doom_bottom_color = 0x00F4EEFF',  # Fogo brilhante na base
    }

    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    with open(config_path, 'w') as f:
        f.write(content)

    print("Configuração do Ly atualizada com sucesso! 🚀 O fogo lilás e o tema estão ativos.")
except PermissionError:
    print("Erro: Permissão negada. Você precisa rodar este script como root (sudo).")
except Exception as e:
    print(f"Erro ao atualizar o Ly: {e}")
