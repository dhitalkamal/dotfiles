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
  -- Close current pane (closes window when last pane)
  { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentPane { confirm = false } },
  -- Font size
  { key = '+', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  -- Clipboard
  { key = 'c', mods = 'CMD', action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection' },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
  -- Search
  { key = 'f', mods = 'CMD', action = wezterm.action.Search { CaseSensitiveString = '' } },
  -- Scroll
  { key = 'UpArrow', mods = 'CMD', action = wezterm.action.ScrollToTop },
  { key = 'DownArrow', mods = 'CMD', action = wezterm.action.ScrollToBottom },
  -- Panes: split (matches iTerm)
  -- CMD+D opens a pane to the right, CMD+SHIFT+D opens a pane below
  { key = 'd', mods = 'CMD', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
  -- Panes: navigate with CMD+OPT+arrow
  { key = 'LeftArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|OPT', action = wezterm.action.ActivatePaneDirection 'Down' },
  -- Panes: resize with CMD+OPT+SHIFT+arrow
  { key = 'LeftArrow', mods = 'CMD|OPT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'CMD|OPT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow', mods = 'CMD|OPT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow', mods = 'CMD|OPT|SHIFT', action = wezterm.action.AdjustPaneSize { 'Down', 5 } },
  -- Clear screen and scrollback
  { key = 'k', mods = 'CMD', action = wezterm.action.ClearScrollback 'ScrollbackAndViewport' },
  -- Toggle fullscreen (macOS standard)
  { key = 'f', mods = 'CMD|CTRL', action = wezterm.action.ToggleFullScreen },
  -- Copy mode (vim-style scrollback navigation)
  { key = 'x', mods = 'CMD|SHIFT', action = wezterm.action.ActivateCopyMode },
  -- Quick select (visually pick text without the mouse)
  { key = ' ', mods = 'CMD|SHIFT', action = wezterm.action.QuickSelect },
  -- Reload config (default exists, made explicit)
  { key = 'r', mods = 'CMD|SHIFT', action = wezterm.action.ReloadConfiguration },
}

-- Mouse: auto-copy on selection, right-click pastes
config.mouse_bindings = {
  -- left-click release auto-copies selection to clipboard
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- double-click selects word and copies
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- triple-click selects line and copies
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- ctrl-click on a link opens it
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  -- right-click pastes
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

return config
