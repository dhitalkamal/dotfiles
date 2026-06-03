local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font('JetBrainsMono Nerd Font Mono')
config.font_size = 14.0
config.line_height = 1.1

-- Color scheme (matches neovim tokyonight-night)
config.color_scheme = 'Tokyo Night'

-- Window
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'
config.initial_cols = 220
config.initial_rows = 50

-- Disable tabs entirely
config.enable_tab_bar = false

-- Performance
config.max_fps = 120
config.animation_fps = 60

-- Scrollback
config.scrollback_lines = 10000

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500

-- Shell
config.default_prog = { '/bin/zsh', '-l' }

-- macOS
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true
config.macos_window_background_blur = 20
config.window_background_opacity = 0.60

-- Keybindings (matching macOS conventions)
config.keys = {
  -- Windows
  { key = 'n', mods = 'CMD', action = wezterm.action.SpawnWindow },
  { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab { confirm = false } },
  -- Font size
  { key = '+', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  -- Clipboard
  { key = 'c', mods = 'CMD', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
  -- Search
  { key = 'f', mods = 'CMD', action = wezterm.action.Search { CaseSensitiveString = '' } },
  -- Scroll
  { key = 'UpArrow', mods = 'CMD', action = wezterm.action.ScrollToTop },
  { key = 'DownArrow', mods = 'CMD', action = wezterm.action.ScrollToBottom },
}

return config
