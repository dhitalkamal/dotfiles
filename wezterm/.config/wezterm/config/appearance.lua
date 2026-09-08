-- appearance: fonts, color scheme, window chrome, tab bar look, gpu perf.
-- everything here mutates the shared config table via M.apply(config).

local wezterm = require 'wezterm'

local M = {}

function M.apply(config)
  -- fonts
  -- main face plus a fallback chain so glyphs never render as tofu:
  --   1. JetBrainsMono Nerd Font Mono  - primary, ligatures + powerline
  --   2. Symbols Nerd Font Mono        - extra icon coverage
  --   3. Apple Color Emoji             - colour emoji
  config.font = wezterm.font_with_fallback {
    {
      family = 'JetBrainsMono Nerd Font Mono',
      weight = 'Medium',
      -- harfbuzz opentype features: keep ligatures (calt/liga) on,
      -- turn on a couple of stylistic sets jetbrains ships.
      harfbuzz_features = { 'calt=1', 'liga=1', 'ss01=1', 'ss02=1' },
    },
    { family = 'Symbols Nerd Font Mono', scale = 0.9 },
    'Apple Color Emoji',
  }
  config.font_size = 14.0
  config.line_height = 1.1
  config.cell_width = 1.0
  -- distinct italic/bold faces so styled text is actually distinguishable
  config.font_rules = {
    {
      intensity = 'Bold',
      italic = false,
      font = wezterm.font { family = 'JetBrainsMono Nerd Font Mono', weight = 'Bold' },
    },
    {
      intensity = 'Normal',
      italic = true,
      font = wezterm.font { family = 'JetBrainsMono Nerd Font Mono', style = 'Italic' },
    },
    {
      intensity = 'Bold',
      italic = true,
      font = wezterm.font { family = 'JetBrainsMono Nerd Font Mono', weight = 'Bold', style = 'Italic' },
    },
  }
  -- crisper glyph edges on retina
  config.freetype_load_target = 'Light'
  config.freetype_render_target = 'HorizontalLcd'

  -- colours
  config.color_scheme = 'Tokyo Night'
  -- override just the tab bar colours so the powerline tabs sit on the
  -- window background instead of the default grey strip.
  config.colors = {
    tab_bar = {
      background = '#1a1b26',
      new_tab = { bg_color = '#1a1b26', fg_color = '#565f89' },
      new_tab_hover = { bg_color = '#292e42', fg_color = '#c0caf5' },
    },
  }
  -- visual bell flash instead of an audible beep (like ghostty/kitty)
  config.audible_bell = 'Disabled'
  config.visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = 'CursorColor',
  }

  -- window
  config.window_padding = { left = 10, right = 10, top = 8, bottom = 6 }
  config.window_decorations = 'RESIZE'
  config.window_close_confirmation = 'NeverPrompt'
  config.initial_cols = 220
  config.initial_rows = 50
  -- opacity without macos blur: blur forced windowserver to continuously
  -- recomposite the desktop behind this window, which was a big driver of
  -- gpu heat. plain opacity is cheap since it doesn't touch the compositor.
  config.window_background_opacity = 0.85
  config.adjust_window_size_when_changing_font_size = false
  config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.75 }

  -- tab bar: retro (custom powerline) rather than the native title-bar style.
  -- always shown, even with a single tab.
  config.enable_tab_bar = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false
  config.tab_bar_at_bottom = false
  config.tab_max_width = 32
  config.show_new_tab_button_in_tab_bar = true
  config.switch_to_last_active_tab_when_closing_tab = true

  -- cursor
  config.default_cursor_style = 'BlinkingBlock'
  config.cursor_blink_rate = 500
  config.cursor_blink_ease_in = 'Constant'
  config.cursor_blink_ease_out = 'Constant'

  -- scrollback: bumped well past the old 10k for warp-like history depth
  config.scrollback_lines = 50000
  config.enable_scroll_bar = true

  -- gpu / perf: webgpu front end but tuned for efficiency, not max smoothness.
  -- a terminal doesn't need 120fps or the high-power gpu tier; both were
  -- keeping the gpu (and windowserver) continuously busy and driving heat.
  config.front_end = 'WebGpu'
  config.webgpu_power_preference = 'LowPower'
  config.max_fps = 60
  config.animation_fps = 24
end

return M
