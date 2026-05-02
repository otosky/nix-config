return {
  {
    "folke/sidekick.nvim",
    opts = {
      -- Keep Sidekick's CLI integrations, but never start/configure Copilot NES.
      nes = { enabled = false },
      copilot = {
        status = {
          enabled = false,
          level = vim.log.levels.OFF,
        },
      },
    },
  },
}
