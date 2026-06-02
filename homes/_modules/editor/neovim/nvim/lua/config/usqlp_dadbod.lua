local M = {}

local query_state
local status_timer

local function encode_url_component(value)
  return tostring(value):gsub("([^%w%-%._~])", function(char)
    return string.format("%%%02X", string.byte(char))
  end)
end

function M.connection_url(connection)
  return "usqlp:" .. encode_url_component(connection)
end

local function is_usqlp_db(db)
  local url = type(db) == "table" and db.url or db
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
      if not is_usqlp_db(db) then
        table.insert(preserved, db)
      end
    end
  else
    for name, url in pairs(dbs) do
      if not is_usqlp_db(url) then
        table.insert(preserved, { name = name, url = url })
      end
    end
  end

  return preserved
end

local function trimmed_lines(start_line, end_line)
  return vim.trim(table.concat(vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false), "\n"))
end

local function now_milliseconds()
  return (vim.uv or vim.loop).hrtime() / 1000000
end

local function elapsed_seconds(start_time, now)
  return math.floor(((now - start_time) / 1000) * 10 + 0.5) / 10
end

local function query_output_from_match(match)
  if type(match) ~= "string" then
    return nil
  end

  return match:gsub("/DBExecutePre$", ""):gsub("/DBExecutePost$", "")
end

local function db_url(value)
  if type(value) == "string" then
    return value
  end
  if type(value) == "table" and type(value.db_url) == "string" then
    return value.db_url
  end
  return nil
end

local function current_db()
  return db_url(vim.b.db) or db_url(vim.w.db) or db_url(vim.g.db) or "unknown connection"
end

local function redraw_statusline()
  pcall(vim.cmd, "redrawstatus")
end

local function stop_status_timer()
  if not status_timer then
    return
  end

  status_timer:stop()
  status_timer:close()
  status_timer = nil
end

local function start_status_timer(timer_factory)
  stop_status_timer()
  local factory = timer_factory or (vim.uv or vim.loop).new_timer
  status_timer = factory()
  status_timer:start(1000, 1000, function()
    vim.schedule(redraw_statusline)
  end)
end

function M.reset_query_observability()
  query_state = nil
  stop_status_timer()
  redraw_statusline()
end

function M.record_query_start(opts)
  opts = opts or {}
  local notify = opts.notify or vim.notify
  local started_at = (opts.now or now_milliseconds)()
  query_state = {
    connection = tostring(opts.connection or current_db()),
    output = query_output_from_match(opts.match),
    started_at = started_at,
  }
  redraw_statusline()
  start_status_timer(opts.timer_factory)

  notify("DB query started: " .. query_state.connection, vim.log.levels.INFO)
  return query_state
end

function M.record_query_finish(opts)
  opts = opts or {}
  local notify = opts.notify or vim.notify
  local finished_at = (opts.now or now_milliseconds)()
  local finished_output = query_output_from_match(opts.match)
  local state = query_state

  if not state or state.output ~= finished_output then
    return nil
  end

  query_state = nil
  stop_status_timer()
  redraw_statusline()

  local elapsed = elapsed_seconds(state.started_at, finished_at)
  notify(string.format("DB query finished in %.1fs: %s", elapsed, state.connection), vim.log.levels.INFO)
  return state
end

function M.query_status(opts)
  opts = opts or {}
  if not query_state then
    return nil
  end

  local now = (opts.now or now_milliseconds)()
  return {
    connection = query_state.connection,
    output = query_state.output,
    started_at = query_state.started_at,
    elapsed_seconds = elapsed_seconds(query_state.started_at, now),
  }
end

function M.query_status_message(opts)
  local status = M.query_status(opts)
  if not status then
    return "No DB query running"
  end

  return string.format("DB query running for %.1fs: %s", status.elapsed_seconds, status.connection)
end

function M.statusline(opts)
  local status = M.query_status(opts)
  if not status then
    return ""
  end

  return string.format("DB %.1fs %s", status.elapsed_seconds, status.connection)
end

function M.cancel_query(opts)
  opts = opts or {}
  local notify = opts.notify or vim.notify
  if not query_state then
    notify("No DB query running", vim.log.levels.INFO)
    return false
  end

  local cancel = opts.cancel
  local exists = opts.exists or vim.fn.exists
  if cancel == nil and exists("*db#cancel") == 1 then
    local output = query_state.output
    local bufnr = opts.bufnr or vim.fn.bufnr
    local db_cancel = opts.db_cancel or vim.fn["db#cancel"]
    cancel = function()
      db_cancel(bufnr(output))
    end
  end

  if not cancel then
    notify("DB query cancellation is not available", vim.log.levels.ERROR)
    return false
  end

  cancel()
  query_state = nil
  stop_status_timer()
  redraw_statusline()
  notify("DB query cancelled", vim.log.levels.WARN)
  return true
end

function M.setup_query_observability()
  local group = vim.api.nvim_create_augroup("usqlp_dadbod_query_observability", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "*DBExecutePre",
    callback = function(event)
      M.record_query_start({ match = event.match })
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "*DBExecutePost",
    callback = function(event)
      M.record_query_finish({ match = event.match })
    end,
  })
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

  if end_line < 0 then
    end_line = vim.api.nvim_buf_line_count(0)
  end

  return trimmed_lines(start_line, end_line)
end

function M.range_query(start_line, end_line)
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  return trimmed_lines(start_line, end_line)
end

function M.visual_query()
  return M.range_query(vim.fn.line("'<"), vim.fn.line("'>"))
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
  if not connections or #connections == 0 then
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

    local cmd = opts.cmd or vim.cmd
    vim.g.db = url
    vim.b.db = url
    cmd("DB! " .. url .. " < " .. vim.fn.fnameescape(query_path))
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
  M.setup_query_observability()

  vim.api.nvim_create_user_command("UsqlpDBUI", function()
    M.open_dbui()
  end, {})
  vim.api.nvim_create_user_command("UsqlpDBUIRefresh", function()
    M.refresh_connections()
  end, {})
  vim.api.nvim_create_user_command("UsqlpDB", function(command)
    local opts = {}
    if command.range > 0 then
      opts.query = M.range_query(command.line1, command.line2)
    end
    M.execute_query(opts)
  end, { range = true })
  vim.api.nvim_create_user_command("UsqlpDBStatus", function()
    vim.notify(M.query_status_message(), vim.log.levels.INFO)
  end, {})
  vim.api.nvim_create_user_command("UsqlpDBCancel", function()
    M.cancel_query()
  end, {})
end

return M
