export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY

source "$ZSH/oh-my-zsh.sh"
export TERM="xterm-256color"

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/postgresql@17/bin:$HOME/.local/bin:$HOME/.kiro:$PATH"

if [[ -z "${KIRO_MCP_LOADED:-}" && -f "$HOME/.kiro/.env.mcp" ]]; then
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    key="${line%%=*}"
    value="${line#*=}"
    [[ -z "$key" || "$key" == "$line" ]] && continue
    export "$key=$value"
  done < "$HOME/.kiro/.env.mcp"
  export KIRO_MCP_LOADED=1
fi

export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

if command -v mcfly >/dev/null 2>&1; then
  eval "$(mcfly init zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

FZF_BASE="/opt/homebrew/opt/fzf"
if [[ ! -d "$FZF_BASE" ]] && command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix)/opt/fzf"
fi
[[ -f "$FZF_BASE/shell/key-bindings.zsh" ]] && source "$FZF_BASE/shell/key-bindings.zsh"
[[ -f "$FZF_BASE/shell/completion.zsh" ]] && source "$FZF_BASE/shell/completion.zsh"

alias cd='z'
alias cat='bat --style=auto'
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias tree='eza --tree --icons'
alias grep='rg'
alias lg='lazygit'
alias top='btop'
alias pps='procs'
alias du='dust'
alias df='duf'
alias sed='sd'
alias help='tldr'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias fm='yazi'

zz() {
  if ! command -v zellij >/dev/null 2>&1; then
    echo "zellij is not installed"
    return 1
  fi
  local session="${1:-${PWD:t}}"
  session="${session//[^[:alnum:]_-]/-}"
  command zellij attach -c "$session"
}

zweb_start() {
  if ! command -v zellij >/dev/null 2>&1; then
    echo "zellij is not installed"
    return 1
  fi
  local web_state
  web_state="$(zellij web --status 2>&1 || true)"
  if [[ "$web_state" != *"online"* ]]; then
    zellij web --start --daemonize >/dev/null
  fi
  zellij web --status
}

zweb_stop() {
  command -v zellij >/dev/null 2>&1 || { echo "zellij is not installed"; return 1; }
  zellij web --stop
}

zshare() {
  command -v zellij >/dev/null 2>&1 || { echo "zellij is not installed"; return 1; }
  zweb_start >/dev/null || return 1
  local out token
  out="$(zellij web --create-token)"
  token="$(printf '%s\n' "$out" | /usr/bin/sed -n 's/^token_[0-9][0-9]*: //p' | head -n1)"
  printf '%s\n' "$out"
  echo "Open: http://127.0.0.1:8082"
  [[ -n "${ZELLIJ_SESSION_NAME:-}" ]] && echo "Current session: ${ZELLIJ_SESSION_NAME}" || echo "Tip: run zz first to enter your target session."
  [[ -n "$token" ]] && echo "Token: $token"
}

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

alias py='python'
alias pip='pip'
alias venv='python -m venv .venv'
activate() {
  if [[ -f ".venv/bin/activate" ]]; then
    source ".venv/bin/activate"
  elif [[ -f "venv/bin/activate" ]]; then
    source "venv/bin/activate"
  else
    echo "No virtual environment found (.venv or venv)."
    return 1
  fi
}

alias pm='python manage.py'
alias pmr='python manage.py runserver'
alias pmm='python manage.py migrate'
alias pmmk='python manage.py makemigrations'
alias pms='python manage.py shell'

alias uvrun='uvicorn main:app --reload'

alias dev='npm run dev'
alias build='npm run build'
alias nid='npm install && npm run dev'

alias dk='docker'
alias dkps='docker ps'
alias dkup='docker compose up -d'
alias dkdown='docker compose down'
alias dkbuild='docker compose build'

if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
