return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local m = function(keys, fn, desc)
          vim.keymap.set("n", keys, fn, { buffer = buf, desc = desc })
        end
        m("]h", function() gs.nav_hunk("next") end, "Next git hunk")
        m("[h", function() gs.nav_hunk("prev") end, "Prev git hunk")
        m("<leader>hs", gs.stage_hunk, "Stage hunk")
        m("<leader>hr", gs.reset_hunk, "Reset hunk")
        m("<leader>hp", gs.preview_hunk, "Preview hunk")
        m("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        m("<leader>hd", gs.diffthis, "Diff this")
      end,
    },
  },
}
