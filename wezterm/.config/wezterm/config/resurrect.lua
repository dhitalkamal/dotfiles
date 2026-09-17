-- resurrect: session persistence plugin (save/restore pane+tab layout per
-- workspace across wezterm restarts). pulled from github on first load.
-- https://github.com/MLFlexer/resurrect.wezterm

local wezterm = require 'wezterm'
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

-- auto-save every 15 minutes so a crash/quit doesn't lose the layout
resurrect.state_manager.periodic_save {
  interval_seconds = 900,
  save_workspaces = true,
}

local M = {}

-- save the active workspace's pane/tab layout to disk
M.save = wezterm.action_callback(function(window, pane)
  resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
end)

-- fuzzy-pick a saved workspace state and restore its panes/tabs
M.restore = wezterm.action_callback(function(window, pane)
  resurrect.fuzzy_loader.fuzzy_load(window, pane, function(id, label)
    local kind = string.match(id, '^([^/]+)')
    local state_id = string.match(id, '([^/]+)$'):gsub('%..+$', '')
    local opts = {
      relative = true,
      restore_text = true,
      on_pane_restore = resurrect.tab_state.default_on_pane_restore,
    }
    if kind == 'workspace' then
      local state = resurrect.state_manager.load_state(state_id, 'workspace')
      resurrect.workspace_state.restore_workspace(state, opts)
    end
  end)
end)

return M
