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
  { "ggandor/leap.nvim", enabled = false },
  { "ggandor/flit.nvim", enabled = false },
}
