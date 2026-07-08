# emacs-style line editing (oh-my-zsh used to set this)
bindkey -e

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY INC_APPEND_HISTORY EXTENDED_HISTORY

# completion (oh-my-zsh used to run this). regenerates the dump when stale.
autoload -Uz compinit
compinit -d "$HOME/.zcompdump"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu no

export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/opt/homebrew/opt/postgresql@16/bin:$HOME/.local/bin:$PATH"

# gpg needs to know which tty to use for passphrase prompts
export GPG_TTY=$(tty)

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
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

# fzf-tab: fzf-powered tab completion. load after compinit and fzf, and before
# autosuggestions/syntax-highlighting. needs 'menu no' set above to take over.
if [[ -f /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh ]]; then
  source /opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath'
fi

# mcfly owns ctrl-r. init after fzf key-bindings.zsh so mcfly wins the ctrl-r
# binding; fzf keeps ctrl-t (files) and alt-c (dirs).
if command -v mcfly >/dev/null 2>&1; then
  eval "$(mcfly init zsh)"
fi

alias cd='z'
alias cat='bat --style=auto'
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias tree='eza --tree --icons'
# search with rg directly. grep stays real grep so its regex/flags do not surprise.
alias lg='lazygit'
alias top='btop'
alias pps='procs'
alias du='dust'
alias df='duf'
alias help='tldr'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias fm='yazi'

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
alias venv='python -m venv .venv'

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

# reveal in finder. f opens cwd; f dir opens folder; f file selects it in finder.
f() {
  if [ $# -eq 0 ]; then
    open .
  elif [ -d "$1" ]; then
    open "$1"
  elif [ -f "$1" ]; then
    open -R "$1"
  else
    open "$1"
  fi
}

if [[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

if [[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# direnv: per-project env auto-load (.envrc). before zoxide so zoxide stays the
# last hook to register.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# pnpm
export PNPM_HOME="/Users/kamaldhital/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
