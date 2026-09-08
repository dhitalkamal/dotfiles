-- workspace helpers: session-style named workspaces like iterm2 profiles /
-- tmux sessions. switch with a fuzzy launcher, create with a prompt.

local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- fuzzy switcher over existing workspaces (leader+s)
M.switch = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES', title = 'workspaces' }

-- prompt for a name, switch to it (creating it if new) (leader+shift+s)
M.create = act.PromptInputLine {
  description = wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { AnsiColor = 'Fuchsia' } },
    { Text = 'new workspace name:' },
  },
  action = wezterm.action_callback(function(window, pane, line)
    if line and line ~= '' then
      window:perform_action(act.SwitchToWorkspace { name = line }, pane)
    end
  end),
}

-- cycle to the next / previous workspace without the picker
M.next = act.SwitchWorkspaceRelative(1)
M.prev = act.SwitchWorkspaceRelative(-1)

-- create/switch to a named workspace, then ask for its starting directory.
-- blank cwd falls back to home_dir; leading '~' is expanded manually since
-- wezterm does not expand it for a raw cwd string.
M.create_with_cwd = act.PromptInputLine {
  description = wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { AnsiColor = 'Fuchsia' } },
    { Text = 'new workspace name:' },
  },
  action = wezterm.action_callback(function(window, pane, name)
    if not name or name == '' then
      return
    end
    window:perform_action(
      act.PromptInputLine {
        description = wezterm.format {
          { Attribute = { Intensity = 'Bold' } },
          { Foreground = { AnsiColor = 'Fuchsia' } },
          { Text = 'starting directory (blank = home):' },
        },
        action = wezterm.action_callback(function(window2, pane2, cwd)
          local resolved_cwd = wezterm.home_dir
          if cwd and cwd ~= '' then
            resolved_cwd = cwd:gsub('^~', wezterm.home_dir)
          end
          window2:perform_action(
            act.SwitchToWorkspace {
              name = name,
              spawn = { cwd = resolved_cwd },
            },
            pane2
          )
        end),
      },
      pane
    )
  end),
}

return M
