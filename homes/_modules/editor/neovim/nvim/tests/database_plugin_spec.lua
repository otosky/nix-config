local function assert_eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

local function find_plugin(plugins, name)
  for _, plugin in ipairs(plugins) do
    if plugin[1] == name then
      return plugin
    end
  end
end

local setup_called = false
package.loaded["config.usqlp_dadbod"] = {
  setup_commands = function()
    setup_called = true
  end,
}

vim.g.db_ui_execute_on_save = 1

local database_plugins = dofile(vim.fn.getcwd() .. "/homes/_modules/editor/neovim/nvim/lua/plugins/database.lua")

local dadbod = find_plugin(database_plugins, "tpope/vim-dadbod")
assert_eq(dadbod.version, false)

local dadbod_ui = find_plugin(database_plugins, "kristijanhusak/vim-dadbod-ui")
dadbod_ui.init()

assert_eq(vim.g.db_ui_execute_on_save, 0)
assert_eq(setup_called, true)

local lualine = find_plugin(database_plugins, "nvim-lualine/lualine.nvim")
local opts = { sections = { lualine_x = { "encoding" } } }
vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#abcdef" })
lualine.opts(nil, opts)
assert_eq(opts.options, nil)
local db_component = opts.sections.lualine_x[1]
assert_eq(type(db_component), "table")
assert_eq(type(db_component[1]), "function")
assert_eq(db_component.icon, "󰆼")
assert_eq(type(db_component.color), "function")
assert_eq(db_component.color().fg, "#abcdef")
assert_eq(db_component.color().gui, "bold")
assert_eq(type(db_component.cond), "function")
assert_eq(opts.sections.lualine_x[2], "encoding")
