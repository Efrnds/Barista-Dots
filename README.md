# ☕ Barista Dots (Arch Linux + Hyprland)

Bem-vindo ao **Barista Dots**! Aqui você encontra toda a minha configuração pessoal do Arch Linux com o **Hyprland** (um compositor Wayland ultra rápido e customizável), usando o lindíssimo tema Catppuccin Macchiato.

Este repositório acompanha scripts automáticos que fazem todo o trabalho de instalação para você: baixam os pacotes, ativam os serviços, aplicam os temas e configuram o ambiente inteirinho do zero com apenas um comando.

---

## 🛠️ Como Instalar (Passo a Passo)

Para ter essa exata configuração rodando na sua máquina, siga os passos abaixo:

### Passo 1: Instalar o Arch Linux (Minimal)
O script foi projetado para ser rodado em uma instalação limpa. 
Durante a instalação do Arch (seja pelo `archinstall` ou instalação manual), selecione o perfil **Minimal** (ou seja, **NÃO** instale nenhum ambiente gráfico ou Desktop Environment como GNOME/KDE). 

*Nota: Certifique-se de criar o seu usuário comum com permissões de administrador (sudo) e de estar conectado à internet.*

### Passo 2: A Mágica! (Instalação com 1 Comando)
Após reiniciar o computador no seu novo Arch Minimal (que estará apenas numa tela de terminal preta), faça o login com o seu usuário e rode este único comando:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Efrnds/Barista-Dots/main/setup.sh)"
```

### O que o script vai fazer?
- 📦 Baixar o repositório, instalar as dependências base e o **yay** (gerenciador de pacotes do AUR).
- 📥 Baixar e instalar automaticamente **todos** os programas essenciais (Waybar, Rofi, Kitty, Hyprland, Docker, etc) lendo o arquivo `pacotes_instalados.txt`.
- 🎨 Copiar e aplicar os meus temas e arquivos de configuração na sua pasta Home.
- ⚙️ Ativar automaticamente os serviços essenciais (Internet, Bluetooth, Tela de Login `ly`, Docker, etc).
- 🐚 Alterar o seu terminal (shell) padrão para o ZSH.

*(Se preferir fazer manualmente, você pode clonar o repositório com `git clone https://github.com/Efrnds/Barista-Dots.git ~/dotfiles` e rodar `./install.sh` por conta própria).*

---

## 🚀 Pós-instalação
Quando o script terminar de executar, ele vai te avisar. Depois disso, basta reiniciar o seu computador:
```bash
reboot
```
Ao iniciar o PC novamente, a sua tela de login do **ly** já aparecerá. Faça o login e aproveite o seu novo sistema 100% configurado! ☕

---

## ⚠️ Aviso Importante (e Contato)
Essa é a minha primeira vez me aventurando na criação de *dotfiles* e *ricing*! Portanto, pode ser que alguns scripts tenham pequenos problemas ou que algo não funcione perfeitamente em 100% das máquinas.

Se você encontrar algum bug, tiver alguma dúvida ou quiser dar alguma sugestão, sinta-se à vontade para me enviar um e-mail em: **efrnds@proton.me**. Ficarei feliz em ajudar (e aprender) com você!
