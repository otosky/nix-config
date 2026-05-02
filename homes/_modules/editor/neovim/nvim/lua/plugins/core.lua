return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-storm",
      news = { lazyvim = false, neovim = false },
    },
  },
  { "neovim/nvim-lspconfig", version = false },
  { "mason-org/mason-lspconfig.nvim", version = false },
  { "mason-org/mason.nvim", version = false },

  "nvim-treesitter/nvim-treesitter-context",

  -- disable any unwanted default LazyVim plugs
  { "akinsho/bufferline.nvim", enabled = false },

  {
    "folke/flash.nvim",
    keys = {
      { "s", false, mode = { "n", "x", "o" } },
      { "S", false, mode = { "n", "x", "o" } },
      {
        "<leader>j",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash",
      },
      {
        "<leader>J",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
    },
  },
}
