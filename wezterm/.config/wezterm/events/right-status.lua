-- iterm2-style status bar on the right of the tab bar: workspace name,
-- current working directory, battery, and clock. also sets the left status
-- to show the active key table (leader mode indicator).

local wezterm = require 'wezterm'

local M = {}

-- pull a short cwd out of the pane's file:// url
local function cwd_of(pane)
  local uri = pane and pane:get_current_working_dir()
  if not uri then
    return ''
  end
  -- newer wezterm returns a Url object with .file_path
  local path = type(uri) == 'userdata' and uri.file_path or tostring(uri):gsub('^file://[^/]*', '')
  if not path or path == '' then
    return ''
  end
  local home = os.getenv 'HOME' or ''
  path = path:gsub('^' .. home, '~')
  -- keep only the last two path segments to stay compact
  local segs = {}
  for s in path:gmatch '[^/]+' do
    segs[#segs + 1] = s
  end
  local n = #segs
  if n == 0 then
    return '/'
  elseif n == 1 then
    return segs[1]
  end
  return segs[n - 1] .. '/' .. segs[n]
end

-- battery glyph + percent, or empty string on a desktop
local function battery()
  local out = ''
  for _, b in ipairs(wezterm.battery_info()) do
    local pct = b.state_of_charge * 100
    local icon = wezterm.nerdfonts.md_battery
    if b.state == 'Charging' then
      icon = wezterm.nerdfonts.md_battery_charging
    elseif pct < 20 then
      icon = wezterm.nerdfonts.md_battery_20
    elseif pct < 50 then
      icon = wezterm.nerdfonts.md_battery_50
    elseif pct < 80 then
      icon = wezterm.nerdfonts.md_battery_80
    end
    out = string.format('%s %.0f%%', icon, pct)
  end
  return out
end

function M.setup()
  -- left status: show when a leader key table is active, so leader mode is
  -- visible instead of silent.
  wezterm.on('update-status', function(window, _)
    local name = window:active_key_table()
    local left = ''
    if name then
      left = wezterm.format {
        { Background = { Color = '#bb9af7' } },
        { Foreground = { Color = '#1a1b26' } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = ' ' .. name .. ' ' },
      }
    elseif window:leader_is_active() then
      left = wezterm.format {
        { Background = { Color = '#f7768e' } },
        { Foreground = { Color = '#1a1b26' } },
        { Attribute = { Intensity = 'Bold' } },
        { Text = ' LEADER ' },
      }
    end
    window:set_left_status(left)
  end)

  wezterm.on('update-right-status', function(window, pane)
    local ws = window:active_workspace()
    local cwd = cwd_of(pane)
    local bat = battery()
    local clock = wezterm.strftime '%a %b %-d  %H:%M'

    local cells = {}
    local function push(icon, text, color)
      if text and text ~= '' then
        cells[#cells + 1] = { Foreground = { Color = color } }
        cells[#cells + 1] = { Text = icon .. ' ' .. text .. '  ' }
      end
    end

    push(wezterm.nerdfonts.cod_terminal_tmux, ws, '#7dcfff')
    push(wezterm.nerdfonts.md_folder, cwd, '#9ece6a')
    if bat ~= '' then
      push('', bat, '#e0af68')
    end
    push(wezterm.nerdfonts.md_clock_outline, clock, '#c0caf5')

    window:set_right_status(wezterm.format(cells))
  end)
end

return M
