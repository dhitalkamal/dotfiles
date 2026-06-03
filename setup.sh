#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES=(git zsh wezterm starship nvim claude)
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

for module in "${MODULES[@]}"; do
  stow "$module"
done

if [[ ! -f "$HOME/.gitconfig_device" ]]; then
  cat >"$HOME/.gitconfig_device" <<'EOF'
[user]
    name = Your Name
    email = your@email.com
EOF
  echo "Created ~/.gitconfig_device (please edit your name/email)."
fi

CURRENT_LOGIN_SHELL="$(dscl . -read /Users/$USER UserShell | awk '{print $2}')"
if [[ "$CURRENT_LOGIN_SHELL" != "/bin/zsh" ]]; then
  echo "Set zsh as default shell:"
  echo "  chsh -s /bin/zsh"
fi

echo "Done. Reload shell with: exec zsh -l"
