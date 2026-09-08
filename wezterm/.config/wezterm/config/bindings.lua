-- bindings: leader key, keyboard shortcuts, key tables, mouse, command
-- palette, hyperlink hints, launch menu and a snippets picker.

local wezterm = require 'wezterm'
local act = wezterm.action
local ws = require 'config.workspaces'
local resurrect = require 'config.resurrect'

local M = {}

-- snippets: warp-style reusable command pickers. label is what you see,
-- text is sent to the active pane (with a trailing newline to run it).
-- keyed by id because InputSelector choice entries only accept id + label.
local snippets = {
  ['git-status'] = { label = 'git status', text = 'git status\n' },
  ['git-log'] = { label = 'git log oneline graph', text = 'git log --oneline --graph --decorate -20\n' },
  ['pnpm-dev'] = { label = 'pnpm dev', text = 'pnpm dev\n' },
  ['pnpm-test'] = { label = 'pnpm test watch', text = 'pnpm test --watch\n' },
  ['prettier'] = { label = 'prettier write', text = 'pnpm prettier --write .\n' },
  ['docker-ps'] = { label = 'docker ps', text = 'docker ps\n' },
  ['ports'] = { label = 'ports in use', text = 'lsof -iTCP -sTCP:LISTEN -n -P\n' },
  ['disk'] = { label = 'disk usage here', text = 'du -sh * | sort -h\n' },
}

-- build the choices list (id + label only) in a stable order
local snippet_choices = {}
for _, id in ipairs {
  'git-status', 'git-log', 'pnpm-dev', 'pnpm-test', 'prettier', 'docker-ps', 'ports', 'disk',
} do
  snippet_choices[#snippet_choices + 1] = { id = id, label = snippets[id].label }
end

local snippet_picker = act.InputSelector {
  title = 'snippets',
  choices = snippet_choices,
  action = wezterm.action_callback(function(_, pane, id, _)
    local s = id and snippets[id]
    if s then
      pane:send_text(s.text)
    end
  end),
}

-- broadcast: one line typed once, sent to every pane in the current tab.
-- closest wezterm-native equivalent to iterm2's broadcast input, for running
-- the same command across several ssh panes at once.
local broadcast_input = act.PromptInputLine {
  description = 'broadcast to all panes in tab:',
  action = wezterm.action_callback(function(window, pane, line)
    if not line or line == '' then
      return
    end
    local tab = window:active_tab()
    if not tab then
      return
    end
    for _, p in ipairs(tab:panes()) do
      p:send_text(line .. '\n')
    end
  end),
}

function M.apply(config)
  -- leader key: tmux-style prefix. ctrl+shift+space then a follow-up key.
  config.leader = { key = 'Space', mods = 'CTRL|SHIFT', timeout_milliseconds = 1500 }

  config.keys = {
    -- windows and tabs
    { key = 'n', mods = 'CMD', action = act.SpawnWindow },
    { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = false } },
    { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
    { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
    -- font size
    { key = '+', mods = 'CMD', action = act.IncreaseFontSize },
    { key = '=', mods = 'CMD', action = act.IncreaseFontSize },
    { key = '-', mods = 'CMD', action = act.DecreaseFontSize },
    { key = '0', mods = 'CMD', action = act.ResetFontSize },
    -- clipboard
    { key = 'c', mods = 'CMD', action = act.CopyTo 'ClipboardAndPrimarySelection' },
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },
    -- search and scrollback nav
    { key = 'f', mods = 'CMD', action = act.Search { CaseSensitiveString = '' } },
    { key = 'UpArrow', mods = 'CMD', action = act.ScrollToTop },
    { key = 'DownArrow', mods = 'CMD', action = act.ScrollToBottom },
    { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },
    -- panes: split (iterm layout - cmd+d right, cmd+shift+d down)
    { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    -- panes: navigate cmd+opt+arrow
    { key = 'LeftArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'CMD|OPT', action = act.ActivatePaneDirection 'Down' },
    -- panes: resize cmd+opt+shift+arrow
    { key = 'LeftArrow', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
    { key = 'RightArrow', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
    { key = 'UpArrow', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
    { key = 'DownArrow', mods = 'CMD|OPT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },
    -- pane zoom toggle (iterm cmd+shift+enter)
    { key = 'Enter', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },
    -- fullscreen
    { key = 'f', mods = 'CMD|CTRL', action = act.ToggleFullScreen },
    -- copy mode and quick select (kitty-style hints)
    { key = 'x', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },
    { key = ' ', mods = 'CMD|SHIFT', action = act.QuickSelect },
    -- workspace switcher / create / cycle: single modifier (left option),
    -- easier to hit than a cmd+shift combo. use the LEFT option key -
    -- right option is set to compose accented characters instead.
    { key = 'w', mods = 'ALT', action = ws.switch },
    { key = 'c', mods = 'ALT', action = ws.create_with_cwd },
    { key = 'n', mods = 'ALT', action = ws.next },
    { key = 'p', mods = 'ALT', action = ws.prev },
    -- session persistence: save/restore a workspace's pane+tab layout
    { key = 's', mods = 'ALT', action = resurrect.save },
    { key = 'r', mods = 'ALT', action = resurrect.restore },
    -- command palette (warp-style) and launchers
    { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },
    { key = 'l', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|LAUNCH_MENU_ITEMS|TABS' } },
    { key = 'e', mods = 'CMD|SHIFT', action = snippet_picker },
    { key = 'b', mods = 'CMD|SHIFT', action = broadcast_input },
    -- reload config
    { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
    -- ssh host picker: fuzzy list of SSH:/SSHMUX: domains from ~/.ssh/config
    { key = 'h', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|DOMAINS', title = 'ssh hosts' } },

    -- leader-prefixed (tmux muscle memory)
    { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
    { key = '|', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
    { key = 'o', mods = 'LEADER', action = act.RotatePanes 'Clockwise' },
    -- workspaces (sessions)
    { key = 's', mods = 'LEADER', action = ws.switch },
    { key = 'S', mods = 'LEADER', action = ws.create },
    { key = 'n', mods = 'LEADER', action = ws.next },
    { key = 'p', mods = 'LEADER', action = ws.prev },
    -- enter the resize key table (press arrows/hjkl repeatedly, esc to exit)
    { key = 'r', mods = 'LEADER', action = act.ActivateKeyTable { name = 'resize', one_shot = false } },
    -- tab index jump 1..9
  }

  -- cmd+1..9 jumps straight to a tab
  for i = 1, 9 do
    table.insert(config.keys, {
      key = tostring(i),
      mods = 'CMD',
      action = act.ActivateTab(i - 1),
    })
  end

  -- key tables: modal resize mode entered from leader+r
  config.key_tables = {
    resize = {
      { key = 'h', action = act.AdjustPaneSize { 'Left', 3 } },
      { key = 'j', action = act.AdjustPaneSize { 'Down', 3 } },
      { key = 'k', action = act.AdjustPaneSize { 'Up', 3 } },
      { key = 'l', action = act.AdjustPaneSize { 'Right', 3 } },
      { key = 'LeftArrow', action = act.AdjustPaneSize { 'Left', 3 } },
      { key = 'DownArrow', action = act.AdjustPaneSize { 'Down', 3 } },
      { key = 'UpArrow', action = act.AdjustPaneSize { 'Up', 3 } },
      { key = 'RightArrow', action = act.AdjustPaneSize { 'Right', 3 } },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'Enter', action = 'PopKeyTable' },
    },
  }

  -- launch menu: quick spawns available from the launcher (cmd+shift+l)
  config.launch_menu = {
    { label = 'zsh login', args = { '/bin/zsh', '-l' } },
    { label = 'htop', args = { '/bin/zsh', '-lc', 'htop || top' } },
    { label = 'lazygit', args = { '/bin/zsh', '-lc', 'lazygit' } },
    { label = 'rhr-frontend dev', cwd = wezterm.home_dir .. '/Work/Recruitables/frontends/rhr-frontend', args = { '/bin/zsh', '-lc', 'pnpm dev' } },
  }

  -- hyperlink hints: auto-underline urls plus jira-style ticket ids and
  -- git commit hashes so they become clickable/quick-selectable.
  config.hyperlink_rules = wezterm.default_hyperlink_rules()
  table.insert(config.hyperlink_rules, {
    regex = [[\b[A-Z]{2,}-\d+\b]],
    format = 'https://recruitablehr.atlassian.net/browse/$0',
  })

  -- quick select: extra patterns matched by cmd+shift+space (hashes, ips,
  -- paths) on top of the built-in url matching.
  config.quick_select_patterns = {
    [[[0-9a-f]{7,40}]], -- git hashes
    [[(\d{1,3}\.){3}\d{1,3}]], -- ipv4
    [[[~./][\w./-]+]], -- file paths
  }

  -- mouse: auto-copy on selection, cmd+click opens links, right-click pastes
  config.mouse_bindings = {
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
      event = { Up = { streak = 2, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
      event = { Up = { streak = 3, button = 'Left' } },
      mods = 'NONE',
      action = act.CompleteSelection 'ClipboardAndPrimarySelection',
    },
    {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CMD',
      action = act.OpenLinkAtMouseCursor,
    },
    {
      event = { Down = { streak = 1, button = 'Right' } },
      mods = 'NONE',
      action = act.PasteFrom 'Clipboard',
    },
  }
end

return M
