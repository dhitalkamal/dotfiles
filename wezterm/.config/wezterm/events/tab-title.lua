-- powerline tab titles with a per-process nerd font icon, active tab
-- highlighted. registered once via M.setup(); wezterm calls it per tab.

local wezterm = require 'wezterm'

local M = {}

-- map a running process basename to a nerd font glyph
local process_icons = {
  ['zsh'] = wezterm.nerdfonts.dev_terminal,
  ['bash'] = wezterm.nerdfonts.cod_terminal_bash,
  ['fish'] = wezterm.nerdfonts.dev_terminal,
  ['nvim'] = wezterm.nerdfonts.custom_vim,
  ['vim'] = wezterm.nerdfonts.custom_vim,
  ['node'] = wezterm.nerdfonts.dev_nodejs_small,
  ['pnpm'] = wezterm.nerdfonts.dev_npm,
  ['npm'] = wezterm.nerdfonts.dev_npm,
  ['python'] = wezterm.nerdfonts.dev_python,
  ['python3'] = wezterm.nerdfonts.dev_python,
  ['git'] = wezterm.nerdfonts.dev_git,
  ['lazygit'] = wezterm.nerdfonts.dev_git,
  ['docker'] = wezterm.nerdfonts.dev_docker,
  ['ssh'] = wezterm.nerdfonts.md_ssh,
  ['wezterm'] = wezterm.nerdfonts.dev_terminal,
  ['cargo'] = wezterm.nerdfonts.dev_rust,
  ['go'] = wezterm.nerdfonts.dev_go,
}

-- powerline separators
local SOLID_LEFT = wezterm.nerdfonts.pl_left_hard_divider
local SOLID_RIGHT = wezterm.nerdfonts.pl_right_hard_divider

-- basename of the foreground process, stripped of path and args
local function proc_name(tab)
  local p = tab.active_pane.foreground_process_name or ''
  return p:gsub('(.*[/\\])(.*)', '%2')
end

local function icon_for(name)
  return process_icons[name] or wezterm.nerdfonts.cod_chevron_right
end

-- title text: explicit tab title if set, else process name
local function title_for(tab)
  local t = tab.tab_title
  if t and #t > 0 then
    return t
  end
  return proc_name(tab)
end

function M.setup()
  wezterm.on('format-tab-title', function(tab, _, _, _, hover, max_width)
    local active = tab.is_active
    local edge_bg = '#1a1b26'
    local bg = active and '#7aa2f7' or (hover and '#292e42' or '#24283b')
    local fg = active and '#1a1b26' or '#c0caf5'

    local icon = icon_for(proc_name(tab))
    local title = title_for(tab)
    -- leave room for index, icon, separators, padding
    local budget = max_width - 6
    if #title > budget then
      title = wezterm.truncate_right(title, budget) .. '\u{2026}'
    end
    local label = string.format(' %d %s %s ', tab.tab_index + 1, icon, title)

    return {
      { Background = { Color = edge_bg } },
      { Foreground = { Color = bg } },
      { Text = SOLID_LEFT },
      { Background = { Color = bg } },
      { Foreground = { Color = fg } },
      { Text = label },
      { Background = { Color = edge_bg } },
      { Foreground = { Color = bg } },
      { Text = SOLID_RIGHT },
    }
  end)
end

return M
