return {
  -- don't need mason since I'm using nix
  { "williamboman/mason.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>cr", false }
      keys[#keys + 1] = { "<leader>cr", vim.lsp.buf.rename }
    end,
  },
  {
    "scalameta/nvim-metals",
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" },
    ft = { "scala", "sbt", "java" },
    config = function()
      local metals_config = require("metals").bare_config()
      metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

      local dap = require("dap")
      dap.configurations.scala = {
        {
          type = "scala",
          request = "launch",
          name = "RunOrTest",
          metals = {
            runType = "runOrTestFile",
            --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
          },
        },
        {
          type = "scala",
          request = "launch",
          name = "Test Target",
          metals = {
            runType = "testTarget",
          },
        },
      }

      metals_config.on_attach = function(client, bufnr)
        require("metals").setup_dap()
      end

      require("metals").initialize_or_attach(metals_config)
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
  {
    "mrcjkb/haskell-tools.nvim",
    version = "^3", -- Recommended
    ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
  },
}
