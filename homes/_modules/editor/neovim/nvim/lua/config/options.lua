-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Disable Neovim's built-in SQL omni-completion maps. They bind insert-mode
-- arrow keys to sqlcomplete drilldown actions, which conflicts with normal
-- cursor movement and our dadbod completion setup.
vim.g.omni_sql_no_default_maps = 1
