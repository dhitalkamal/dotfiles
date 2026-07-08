#!/usr/bin/env bash
# macos defaults for a keyboard- and terminal-centric dev machine.
#
# every write here is reversible: `defaults delete <domain> <key>` restores the
# system default, or flip the bool back. re-running is safe because defaults
# writes are idempotent. some keyboard settings only take full effect after you
# log out and back in.
set -euo pipefail

echo "keyboard: fast key repeat, no press-and-hold, full keyboard access"
# key repeat: lower is faster. 2 is fast without being twitchy (1). initial
# delay 15 units (~225ms) before repeat kicks in.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# disable the accent-character popup so holding a key repeats it. matters for
# vim-style motions (hold j/k) in editors and the terminal.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# tab moves focus through every control in dialogs, not just text boxes.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "finder: show hidden files, extensions, path bar, status bar"
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# search the current folder by default instead of the whole mac.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# no nag when changing a file extension.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

echo "finder: stop writing .DS_Store on network and usb volumes"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

echo "restarting Finder to apply visible changes"
# killall returns non-zero if the process is not running; that is fine here.
killall Finder || true

echo "done. key repeat and press-and-hold fully apply after a logout/login."
