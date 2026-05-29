local function assert_eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

local usqlp_dadbod = dofile(vim.fn.getcwd() .. "/homes/_modules/editor/neovim/nvim/lua/config/usqlp_dadbod.lua")

assert_eq(usqlp_dadbod.connection_url("local_postgres"), "usqlp:local_postgres")
assert_eq(usqlp_dadbod.connection_url("conn name"), "usqlp:conn%20name")

local connections = usqlp_dadbod.parse_connections({ "prod", "", "dev" })
assert_eq(connections[1], "dev")
assert_eq(connections[2], "prod")

vim.g.dbs = {
  { name = "existing", url = "postgres://localhost/example" },
  { name = "old-usqlp", url = "usqlp:old" },
}

local dbs = usqlp_dadbod.refresh_connections({
  systemlist = function(command)
    assert_eq(table.concat(command, " "), "usqlp --list")
    return { "local_postgres", "conn name" }
  end,
  shell_error = 0,
  notify = function() end,
})

assert_eq(#dbs, 3)
assert_eq(dbs[1].name, "existing")
assert_eq(dbs[2].name, "conn name")
assert_eq(dbs[2].url, "usqlp:conn%20name")
assert_eq(dbs[3].name, "local_postgres")
assert_eq(dbs[3].url, "usqlp:local_postgres")
