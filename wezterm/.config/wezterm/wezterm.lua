-- wezterm entry point. keeps this file thin: each concern lives in its own
-- module under config/ and events/, applied to a shared config builder.
--
-- modules:
--   config.appearance    fonts, colours, window, tab bar look, gpu perf
--   config.bindings      leader key, keymaps, mouse, palette, snippets, hints
--   config.domains       ssh domains from ~/.ssh/config
--   events.tab-title     powerline tab titles with process icons
--   events.right-status  status bar (workspace, cwd, battery, clock)
--
-- optional community plugins you can add later (each pulls over the network
-- on first load, so left out to keep this config self-contained):
--   wezterm-session-manager / resurrect.wezterm  save+restore workspaces
--   smart-splits.nvim companion                  seamless nvim<->pane nav
--   see https://github.com/wez/wezterm/wiki/Plugins

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- shell
config.default_prog = { '/bin/zsh', '-l' }
-- term stays at the default xterm-256color because the wezterm terminfo is
-- not installed on this machine; setting term='wezterm' without it breaks
-- colours in vim/tmux/less. to enable the extras (undercurl, extra osc) run:
--   tempfile=$(mktemp) && curl -o "$tempfile" https://raw.githubusercontent.com/wezterm/wezterm/main/termwiz/data/wezterm.terminfo && tic -x -o ~/.terminfo "$tempfile"
-- then uncomment the next line.
-- config.term = 'wezterm'

-- macos option-key behaviour: left alt sends meta, right alt composes
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- apply config modules
require('config.appearance').apply(config)
require('config.bindings').apply(config)
require('config.domains').apply(config)

-- register event handlers (tab titles, status bar)
require('events.tab-title').setup()
require('events.right-status').setup()

return config
