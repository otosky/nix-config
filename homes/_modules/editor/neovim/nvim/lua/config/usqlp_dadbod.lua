local M = {}

local function encode_url_component(value)
  return tostring(value):gsub("([^%w%-%._~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

function M.connection_url(connection)
  return "usqlp:" .. encode_url_component(connection)
end

local function is_usqlp_url(url)
  return type(url) == "string" and vim.startswith(url, "usqlp:")
end

local function existing_non_usqlp_dbs()
  local dbs = vim.g.dbs
  local preserved = {}

  if type(dbs) ~= "table" then
    return preserved
  end

  if vim.islist(dbs) then
    for _, db in ipairs(dbs) do
      if type(db) == "table" then
        if not is_usqlp_url(db.url) then
          table.insert(preserved, db)
        end
      elseif not is_usqlp_url(db) then
        table.insert(preserved, db)
      end
    end
  else
    for name, url in pairs(dbs) do
      if not is_usqlp_url(url) then
        table.insert(preserved, { name = name, url = url })
      end
    end
  end

  return preserved
end

function M.parse_connections(lines)
  local connections = {}
  for _, line in ipairs(lines or {}) do
    local connection = vim.trim(line)
    if connection ~= "" then
      table.insert(connections, connection)
    end
  end
  table.sort(connections)
  return connections
end

function M.list_connections(opts)
  opts = opts or {}
  if opts.connections then
    return opts.connections
  end

  local notify = opts.notify or vim.notify
  local systemlist = opts.systemlist or vim.fn.systemlist
  local lines = systemlist({ "usqlp", "--list" })
  local shell_error = opts.shell_error or vim.v.shell_error
  if shell_error ~= 0 then
    notify("usqlp --list failed", vim.log.levels.ERROR)
    return nil
  end

  return M.parse_connections(lines)
end

function M.refresh_connections(opts)
  opts = opts or {}
  local connections = M.list_connections(opts)
  if not connections then
    return nil
  end

  local dbs = existing_non_usqlp_dbs()
  for _, connection in ipairs(connections) do
    table.insert(dbs, { name = connection, url = M.connection_url(connection) })
  end

  vim.g.dbs = dbs
  return dbs
end

function M.pick_connection(connections, select, callback)
  (select or vim.ui.select)(connections, { prompt = "usqlp connection" }, callback)
end

function M.query_under_cursor()
  local start_line = vim.fn.search("^\\s*$", "bnW") + 1
  local end_line = vim.fn.search("^\\s*$", "nW") - 1

  if start_line == 0 then
    start_line = 1
  end
  if end_line < 0 then
    end_line = vim.api.nvim_buf_line_count(0)
  end

  return vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false), "\n"))
end

function M.visual_query()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  return vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false), "\n"))
end

function M.execute_query(opts)
  opts = opts or {}
  local notify = opts.notify or vim.notify
  local query = vim.trim(opts.query or M.query_under_cursor())
  if query == "" then
    notify("No SQL query selected", vim.log.levels.WARN)
    return
  end

  local connections = M.list_connections(opts)
  if not connections or vim.tbl_isempty(connections) then
    notify("No usqlp connections found", vim.log.levels.WARN)
    return
  end

  M.pick_connection(connections, opts.select, function(connection)
    if not connection then
      return
    end

    local url = M.connection_url(connection)
    local query_path = opts.query_path or (vim.fn.tempname() .. ".sql")
    vim.fn.writefile(vim.split(query, "\n", { plain = true }), query_path)

    vim.g.db = url
    vim.b.db = url;
    (opts.cmd or vim.cmd)("DB! " .. url .. " < " .. vim.fn.fnameescape(query_path))
  end)
end

function M.execute_visual_query(opts)
  opts = opts or {}
  M.execute_query(vim.tbl_extend("force", opts, { query = M.visual_query() }))
end

function M.open_dbui(opts)
  if not M.refresh_connections(opts) then
    return
  end
  vim.cmd("DBUI")
end

function M.toggle_dbui(opts)
  if not M.refresh_connections(opts) then
    return
  end
  vim.cmd("DBUIToggle")
end

function M.setup_commands()
  vim.api.nvim_create_user_command("UsqlpDBUI", function()
    M.open_dbui()
  end, {})
  vim.api.nvim_create_user_command("UsqlpDBUIRefresh", function()
    M.refresh_connections()
  end, {})
  vim.api.nvim_create_user_command("UsqlpDB", function()
    M.execute_query()
  end, { range = true })
end

return M
