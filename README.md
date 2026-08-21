# dotfiles (zsh-first)

Personal macOS dev environment with a clean, conflict-free toolchain.

## included

- zsh config
- kitty terminal
- starship prompt
- neovim config
- git config
- zellij config
- claude code config (settings, hooks, skills, rules)
- Brewfile + one-command setup

## quick setup

```bash
git clone git@github.com:kamaldhitalofficial/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

## manual setup

```bash
brew bundle --file Brewfile
stow git zsh kitty starship nvim zellij
```

Create `~/.gitconfig_device` if missing:

```ini
[user]
    name = Your Name
    email = your@email.com
```

## productivity shortcuts

- `zz` → attach/create zellij session from current directory name
- `zweb_start` → start zellij web server
- `zshare` → create a web token and print URL/token

## claude code config

`setup.sh` requires Homebrew, so it only runs as-is on macOS. On
Linux (no brew), skip the script and stow the claude module by hand:

```bash
git clone git@github.com:dhitalkamal/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow claude
```

Not included, on purpose:

- MCP server credentials (github token, jira oauth). These live in
  `~/.claude.json`, not `~/.claude/`, and are never checked in. Re-add
  them on each machine (`claude mcp add ...` / re-auth jira).
- Auto-memory (`~/.claude/projects/*/memory/`). It can reference
  project-specific secrets (db creds, vpn setup) and its folder name
  is derived from the machine's home path, so it does not stow
  cleanly. Copy files across by hand if wanted.
- `pending/` holds unreviewed hook/skill drafts (see CLAUDE.md's
  agent-tooling review gate) - move into the active dirs only after
  reviewing.

`statusline/statusline.sh` already handles both platforms (macOS
Keychain vs. a Linux `.credentials.json` fallback) - no changes
needed there.

## project templates

```bash
cp templates/.envrc /path/to/project/.envrc
cp templates/.python-version /path/to/project/.python-version
cp templates/.nvmrc /path/to/project/.nvmrc
```
