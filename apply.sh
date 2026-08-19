#!/usr/bin/env bash
# Aplica dotfiles na máquina atual (symlinks). Rode após git pull.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[32m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

link_path() {
  local src="$1" dest="$2"
  if [[ ! -e "$src" ]]; then
    echo -e "${YELLOW}[skip]${RESET} não existe: $src"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local bak="${dest}.pre-dotfiles-$(date +%Y%m%d%H%M%S)"
    echo -e "${YELLOW}[backup]${RESET} $dest -> $bak"
    mv "$dest" "$bak"
  fi
  ln -sfn "$src" "$dest"
  echo -e "${GREEN}[link]${RESET} $dest"
}

link_file() {
  link_path "$1" "$2"
}

install_git_hooks() {
  local hook_dir="$DOTFILES/.git/hooks"
  [[ -d "$DOTFILES/.git" ]] || return 0
  mkdir -p "$hook_dir"
  for hook in post-merge post-checkout; do
    cat > "$hook_dir/$hook" <<EOF
#!/usr/bin/env bash
exec "$DOTFILES/apply.sh"
EOF
    chmod +x "$hook_dir/$hook"
  done
  echo -e "${GREEN}[hook]${RESET} git hooks -> apply.sh (post-merge/post-checkout)"
}

echo -e "${BLUE}=== Aplicando dotfiles ($DOTFILES) ===${RESET}"

echo -e "${BLUE}[*] render templates...${RESET}"
chmod +x "$DOTFILES/hooks/render-config.sh"
"$DOTFILES/hooks/render-config.sh"

mkdir -p "$HOME/.config" "$HOME/.local/bin"

CONFIG_DIRS=(
  hypr
  foot
  tmux
  DankMaterialShell
  nvim
  yazi
  btop
  cava
  fastfetch
  spicetify
)

for dir in "${CONFIG_DIRS[@]}"; do
  link_path "$DOTFILES/config/$dir" "$HOME/.config/$dir"
done

link_file "$DOTFILES/config/starship.toml" "$HOME/.config/starship.toml"

mkdir -p "$HOME/.config/systemd/user"
if [[ -d "$DOTFILES/systemd/user" ]]; then
  for unit in "$DOTFILES/systemd/user/"*; do
    [[ -f "$unit" ]] || continue
    link_file "$unit" "$HOME/.config/systemd/user/$(basename "$unit")"
  done
fi

if [[ -d "$DOTFILES/local-bin" ]]; then
  for bin in "$DOTFILES/local-bin/"*; do
    [[ -f "$bin" ]] || continue
    link_file "$bin" "$HOME/.local/bin/$(basename "$bin")"
  done
fi

for f in .zshrc .bashrc .gitconfig; do
  [[ -f "$DOTFILES/home/$f" ]] && link_file "$DOTFILES/home/$f" "$HOME/$f"
done

install_git_hooks
chmod +x "$DOTFILES/apply.sh" "$DOTFILES/import.sh" "$DOTFILES/install.sh" "$DOTFILES/update.sh" "$DOTFILES/doctor.sh" 2>/dev/null || true
chmod +x "$DOTFILES/hooks/"*.sh 2>/dev/null || true
chmod +x "$DOTFILES/tests/"*.sh 2>/dev/null || true

echo -e "${BLUE}[*] hooks pós-apply...${RESET}"
"$DOTFILES/hooks/post-apply.sh"

echo -e "${GREEN}=== Dotfiles aplicados ===${RESET}"
