return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Default config applied to every server (adds completion capabilities).
      vim.lsp.config("*", { capabilities = capabilities })

      -- Server-specific tweaks.
      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "gopls", "ts_ls", "pyright" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = function(ev)
          local m = function(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
          end
          m("gd", vim.lsp.buf.definition, "Go to definition")
          m("gD", vim.lsp.buf.declaration, "Go to declaration")
          m("gr", vim.lsp.buf.references, "References")
          m("gi", vim.lsp.buf.implementation, "Implementation")
          m("K", vim.lsp.buf.hover, "Hover docs")
          m("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          m("<leader>ca", vim.lsp.buf.code_action, "Code action")
          m("<leader>lf", function() vim.lsp.buf.format({ async = true }) end, "Format buffer")
          m("[d", function() vim.diagnostic.jump({ count = -1 }) end, "Prev diagnostic")
          m("]d", function() vim.diagnostic.jump({ count = 1 }) end, "Next diagnostic")
          m("<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })
    end,
  },
}
