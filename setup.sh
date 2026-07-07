#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES=(git zsh wezterm starship nvim claude warp)
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it first: https://brew.sh"
  exit 1
fi

cd "$REPO_DIR"

echo "Installing/updating packages from Brewfile..."
brew bundle --file "$REPO_DIR/Brewfile"

echo "Applying stow modules: ${MODULES[*]}"
backup_if_regular_file() {
  local path="$1"
  if [[ -e "$path" && ! -L "$path" ]]; then
    local backup="${path}.pre-dotfiles-${TIMESTAMP}"
    mv "$path" "$backup"
    echo "Backed up $path -> $backup"
  fi
}

backup_if_regular_file "$HOME/.zshrc"
backup_if_regular_file "$HOME/.gitconfig"
backup_if_regular_file "$HOME/.config/starship.toml"
backup_if_regular_file "$HOME/.config/wezterm/wezterm.lua"
backup_if_regular_file "$HOME/.config/nvim/init.lua"
backup_if_regular_file "$HOME/.claude/settings.json"
backup_if_regular_file "$HOME/.claude/CLAUDE.md"
backup_if_regular_file "$HOME/.claude/statusline.sh"
backup_if_regular_file "$HOME/.warp/settings.toml"
backup_if_regular_file "$HOME/.warp/keybindings.yaml"
backup_if_regular_file "$HOME/.warp/themes/tokyo-night.yaml"

for module in "${MODULES[@]}"; do
  stow "$module"
done

# link the personal agent workspace if present. it lives at dotfiles/agent
# (gitignored, its own git repo) and is symlinked to ~/agent. on a fresh
# machine, clone the agent repo into dotfiles/agent first, then re-run.
if [[ -d "$REPO_DIR/agent" && ! -e "$HOME/agent" ]]; then
  ln -s dotfiles/agent "$HOME/agent"
  echo "Linked ~/agent -> dotfiles/agent"
fi

if [[ ! -f "$HOME/.gitconfig_device" ]]; then
  cat >"$HOME/.gitconfig_device" <<'DEVEOF'
[user]
    name = Your Name
    email = your@email.com
DEVEOF
  echo "Created ~/.gitconfig_device (please edit your name/email)."
fi

CURRENT_LOGIN_SHELL="$(dscl . -read /Users/$USER UserShell | awk '{print $2}')"
if [[ "$CURRENT_LOGIN_SHELL" != "/bin/zsh" ]]; then
  echo "Set zsh as default shell:"
  echo "  chsh -s /bin/zsh"
fi

echo "Done. Reload shell with: exec zsh -l"
