return {
  -- set versions off for now while lua_ls update becomes stable
  { "folke/lazy.nvim", version = false },
  {
    "LazyVim/LazyVim",
    version = false,
    opts = {
      colorscheme = "tokyonight-storm",
    },
  },
  { "neovim/nvim-lspconfig", version = false },
  { "williamboman/mason-lspconfig.nvim", version = false },
  { "williamboman/mason.nvim", version = false },

  "nvim-treesitter/nvim-treesitter-context",

  -- colorschemes
  "mangeshrex/everblush.vim",
  "doums/darcula",
  "nyoom-engineering/oxocarbon.nvim",
  "rose-pine/neovim",
  "morhetz/gruvbox",

  -- disable any unwanted default LazyVim plugs
  { "akinsho/bufferline.nvim", enabled = false },
  { "ggandor/leap.nvim", enabled = false },
  { "ggandor/flit.nvim", enabled = false },
  { "echasnovski/mini.surround", enabled = false },
}
