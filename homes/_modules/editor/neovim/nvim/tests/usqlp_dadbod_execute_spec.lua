local function assert_eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

local usqlp_dadbod = dofile(vim.fn.getcwd() .. "/homes/_modules/editor/neovim/nvim/lua/config/usqlp_dadbod.lua")

local picked
usqlp_dadbod.pick_connection({ "dev", "prod" }, function(items, opts, callback)
  assert_eq(opts.prompt, "usqlp connection")
  assert_eq(items[1], "dev")
  callback("prod")
end, function(connection)
  picked = connection
end)
assert_eq(picked, "prod")

local executed
local query_path = "/tmp/usqlp-dadbod-execute-spec.sql"
usqlp_dadbod.execute_query({
  query = "select 1;",
  query_path = query_path,
  connections = { "dev" },
  select = function(_, _, callback)
    callback("dev")
  end,
  cmd = function(command)
    executed = command
  end,
  notify = function() end,
})
assert_eq(executed, "DB! usqlp:dev < " .. query_path)
assert_eq(vim.g.db, "usqlp:dev")
assert_eq(vim.b.db, "usqlp:dev")
assert_eq(table.concat(vim.fn.readfile(query_path), "\n"), "select 1;")
