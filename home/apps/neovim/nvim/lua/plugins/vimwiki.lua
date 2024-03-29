return {
  {
    "vimwiki/vimwiki",
    config = function()
      vim.g.vimwiki_list = {
        { path = "~/notes/", syntax = "markdown", ext = ".md" },
      }
    end,
  },
  {
    "michal-h21/vim-zettel",
    config = function()
      vim.g.zettel_format = "%y%m%d-%H%M-%title"
      vim.g.zettel_date_format = "%Y-%m-%dT%H:%M:%S%z"

      local function save_title_to_register(register)
        local fname = vim.fn.expand("%:t")
        local old_title = fname:match(".+-(.+)%.md$")
        local new_title = vim.fn["zettel#vimwiki#get_title"](vim.fn.expand("%"))

        local updated_fname = fname:gsub(old_title, new_title):gsub(".md", "")

        vim.fn.setreg(register, updated_fname)
      end

      local function zettel_prompt_rename()
        save_title_to_register("*")
        vim.cmd("VimwikiRenameFile")
      end

      vim.keymap.set("n", "<leader>zrn", zettel_prompt_rename)
    end,
  },
}
