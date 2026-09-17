return {
  {
    "goolord/alpha-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      dashboard.section.header.val = {
        [[██╗  ██╗ █████╗ ███╗   ███╗ █████╗ ██╗     ]],
        [[██║ ██╔╝██╔══██╗████╗ ████║██╔══██╗██║     ]],
        [[█████╔╝ ███████║██╔████╔██║███████║██║     ]],
        [[██╔═██╗ ██╔══██║██║╚██╔╝██║██╔══██║██║     ]],
        [[██║  ██╗██║  ██║██║ ╚═╝ ██║██║  ██║███████╗]],
        [[╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝]],
      }
      -- Same scheme LazyVim uses: link to theme groups so it matches Catppuccin.
      dashboard.section.header.opts.hl = "Title"

      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
        dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
        dashboard.button("g", "  Live grep", "<cmd>Telescope live_grep<cr>"),
        dashboard.button("e", "  File explorer", "<cmd>Neotree toggle<cr>"),
        dashboard.button("c", "  Config", "<cmd>e $MYVIMRC<cr>"),
        dashboard.button("l", "󰒲  Plugins (Lazy)", "<cmd>Lazy<cr>"),
        dashboard.button("q", "  Quit", "<cmd>qa<cr>"),
      }
      for _, b in ipairs(dashboard.section.buttons.val) do
        b.opts.hl = "Special"
        b.opts.hl_shortcut = "Number"
      end

      dashboard.section.footer.val = "leader = <space>   ·   press a highlighted key"
      dashboard.section.footer.opts.hl = "Comment"

      -- Vertically center: set the top padding from the window height so the
      -- whole block sits in the middle instead of near the top.
      local function center_pad()
        local win_h = vim.api.nvim_win_get_height(0)
        local content = #dashboard.section.header.val
          + 2
          + (2 * #dashboard.section.buttons.val - 1)
          + 1
        return math.max(1, math.floor((win_h - content) / 2))
      end
      dashboard.opts.layout[1].val = center_pad

      alpha.setup(dashboard.opts)

      -- Re-center when the window is resized while the dashboard is open.
      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          if vim.bo.filetype == "alpha" then
            pcall(function() require("alpha").redraw() end)
          end
        end,
      })

      -- Hide the block cursor while the dashboard is open so navigating with
      -- j/k never lights up a stray character. Restored on leaving.
      local grp = vim.api.nvim_create_augroup("alpha_hide_cursor", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = grp,
        pattern = "AlphaReady",
        callback = function()
          vim.opt_local.cursorline = false
          vim.cmd("highlight Cursor blend=100")
          vim.opt.guicursor:append("a:Cursor/lCursor")
          vim.api.nvim_create_autocmd({ "BufLeave", "BufUnload" }, {
            buffer = 0,
            once = true,
            callback = function()
              vim.cmd("highlight Cursor blend=0")
              vim.opt.guicursor:remove("a:Cursor/lCursor")
            end,
          })
        end,
      })
    end,
  },
}
