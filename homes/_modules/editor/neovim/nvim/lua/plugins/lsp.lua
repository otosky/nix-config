return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>cr", false }
      keys[#keys + 1] = { "<leader>cr", vim.lsp.buf.rename }
    end,
  },
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["python"] = { "isort", "black" },
        ["lua"] = { "stylua" },
        ["javascript"] = { { "prettierd", "prettier" } },
        ["scala"] = { "scalafmt" },
        ["ruby"] = { "rufo" },
        ["sh"] = { "shfmt" },
        ["elixir"] = { "mix" },
        ["nix"] = { "alejandra" },
      },
    },
  },
}
