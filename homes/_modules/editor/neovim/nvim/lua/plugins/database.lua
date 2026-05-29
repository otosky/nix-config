return {
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
      require("config.usqlp_dadbod").setup_commands()
    end,
  },
}
