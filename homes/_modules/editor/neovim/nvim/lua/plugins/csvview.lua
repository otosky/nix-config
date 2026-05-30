return {
  {
    "hat0uma/csvview.nvim",
    opts = {
      view = {
        display_mode = "border",
        sticky_header = { enabled = true },
      },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
        jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
        jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
        jump_next_row = { "<Enter>", mode = { "n", "v" } },
        jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
      },
    },
    cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
    ft = { "csv", "tsv", "dbout" },
    config = function(_, opts)
      local csvview = require("csvview")
      csvview.setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "csv", "tsv", "dbout" },
        callback = function(event)
          csvview.enable(event.buf, {
            view = {
              display_mode = "border",
              header_lnum = 1,
              sticky_header = { enabled = true },
            },
          })
        end,
      })
    end,
  },
}
