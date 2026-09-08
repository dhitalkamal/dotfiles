-- domains: ssh domains auto-populated from ~/.ssh/config.
-- for each named Host this creates two domains:
--   SSH:<host>    plain ssh, nothing needed on the remote
--   SSHMUX:<host> persistent/reconnecting mux, needs wezterm on the remote
-- add named Host entries to ~/.ssh/config for them to show up here.

local wezterm = require 'wezterm'

local M = {}

function M.apply(config)
  config.ssh_domains = wezterm.default_ssh_domains()
  for _, dom in ipairs(config.ssh_domains) do
    -- assume a posix remote shell so wezterm sets the session up correctly
    dom.assume_shell = 'Posix'
  end
end

return M
