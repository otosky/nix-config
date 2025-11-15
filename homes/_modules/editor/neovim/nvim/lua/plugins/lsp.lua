return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<leader>cr", vim.lsp.buf.rename },
          },
        },
      },
    },
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
        ["haskell"] = { "ormolu" },
      },
    },
  },
}
