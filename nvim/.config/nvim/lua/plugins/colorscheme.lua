return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
          neotree = true,
          telescope = true,
          gitsigns = true,
          treesitter = true,
          cmp = true,
          mason = true,
          which_key = true,
          alpha = true,
          native_lsp = { enabled = true },
          indent_blankline = { enabled = true },
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
