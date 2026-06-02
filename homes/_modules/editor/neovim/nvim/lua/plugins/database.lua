local function highlight_color(group, key)
  local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
  local color = highlight[key]
  if type(color) ~= "number" then
    return nil
  end

  return string.format("#%06x", color)
end

return {
  {
    "tpope/vim-dadbod",
    version = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, {
        function()
          return require("config.usqlp_dadbod").statusline()
        end,
        icon = "󰆼",
        color = function()
          return { fg = highlight_color("DiagnosticWarn", "fg"), gui = "bold" }
        end,
        cond = function()
          return require("config.usqlp_dadbod").query_status() ~= nil
        end,
      })
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    keys = {
      {
        "<leader>D",
        function()
          require("config.usqlp_dadbod").toggle_dbui()
        end,
        desc = "Toggle DBUI",
      },
      {
        "<leader>uS",
        function()
          require("config.usqlp_dadbod").execute_query()
        end,
        desc = "Run SQL with usqlp",
        ft = "sql",
      },
      {
        "<leader>uS",
        function()
          require("config.usqlp_dadbod").execute_visual_query()
        end,
        desc = "Run SQL selection with usqlp",
        ft = "sql",
        mode = "v",
      },
    },
    init = function()
      vim.g.db_ui_execute_on_save = 0
      require("config.usqlp_dadbod").setup_commands()
    end,
  },
}
