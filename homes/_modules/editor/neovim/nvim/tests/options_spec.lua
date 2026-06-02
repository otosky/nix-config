local function assert_eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

vim.g.omni_sql_no_default_maps = nil

dofile(vim.fn.getcwd() .. "/homes/_modules/editor/neovim/nvim/lua/config/options.lua")

assert_eq(vim.g.omni_sql_no_default_maps, 1)

vim.cmd("filetype plugin on")
vim.cmd("setfiletype sql")

assert_eq(vim.fn.maparg("<Left>", "i", false, true).lhs, nil)
assert_eq(vim.fn.maparg("<Right>", "i", false, true).lhs, nil)
