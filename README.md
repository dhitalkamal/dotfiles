# dotfiles (zsh-first)

Personal macOS dev environment with a clean, conflict-free toolchain.

## included

- zsh config
- kitty terminal
- starship prompt
- neovim config
- git config
- zellij config
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

## project templates

```bash
cp templates/.envrc /path/to/project/.envrc
cp templates/.python-version /path/to/project/.python-version
cp templates/.nvmrc /path/to/project/.nvmrc
```
