local function assert_eq(actual, expected)
  if actual ~= expected then
    error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
  end
end

local function assert_truthy(value)
  if not value then
    error("expected truthy value", 2)
  end
end

local usqlp_dadbod = dofile(vim.fn.getcwd() .. "/homes/_modules/editor/neovim/nvim/lua/config/usqlp_dadbod.lua")

local notifications = {}
local function notify(message, level)
  table.insert(notifications, { message = message, level = level })
end

usqlp_dadbod.reset_query_observability()
vim.b.db = { db_url = "usqlp:dev" }

local fake_timer = {
  start_delay = nil,
  repeat_delay = nil,
  tick = nil,
  stopped = false,
  closed = false,
  start = function(self, start_delay, repeat_delay, tick)
    self.start_delay = start_delay
    self.repeat_delay = repeat_delay
    self.tick = tick
  end,
  stop = function(self)
    self.stopped = true
  end,
  close = function(self)
    self.closed = true
  end,
}

usqlp_dadbod.record_query_start({
  match = "/tmp/query.dbout/DBExecutePre",
  notify = notify,
  now = function()
    return 1000
  end,
  timer_factory = function()
    return fake_timer
  end,
})

assert_eq(#notifications, 1)
assert_eq(notifications[1].message, "DB query started: usqlp:dev")
assert_eq(notifications[1].level, vim.log.levels.INFO)

local status = usqlp_dadbod.query_status({
  now = function()
    return 3500
  end,
})
assert_truthy(status)
assert_eq(status.running, nil)
assert_eq(status.connection, "usqlp:dev")
assert_eq(status.output, "/tmp/query.dbout")
assert_eq(status.elapsed_seconds, 2.5)
assert_eq(usqlp_dadbod.query_status_message({ now = function() return 3500 end }), "DB query running for 2.5s: usqlp:dev")
assert_eq(usqlp_dadbod.statusline({ now = function() return 3500 end }), "DB 2.5s usqlp:dev")
assert_eq(vim.g.usqlp_dadbod_status, nil)
assert_eq(fake_timer.start_delay, 1000)
assert_eq(fake_timer.repeat_delay, 1000)

usqlp_dadbod.record_query_finish({
  match = "/tmp/query.dbout/DBExecutePost",
  notify = notify,
  now = function()
    return 4200
  end,
})

assert_eq(#notifications, 2)
assert_eq(notifications[2].message, "DB query finished in 3.2s: usqlp:dev")
assert_eq(notifications[2].level, vim.log.levels.INFO)
assert_eq(usqlp_dadbod.query_status(), nil)
assert_eq(usqlp_dadbod.query_status_message(), "No DB query running")
assert_eq(usqlp_dadbod.statusline(), "")
assert_eq(vim.g.usqlp_dadbod_status, nil)
assert_eq(fake_timer.stopped, true)
assert_eq(fake_timer.closed, true)

usqlp_dadbod.reset_query_observability()
vim.b.db = "usqlp:dev"
usqlp_dadbod.record_query_start({
  match = "/tmp/a.dbout/DBExecutePre",
  notify = notify,
  now = function()
    return 1000
  end,
})
vim.b.db = "usqlp:prod"
usqlp_dadbod.record_query_start({
  match = "/tmp/b.dbout/DBExecutePre",
  notify = notify,
  now = function()
    return 1500
  end,
})

local notification_count = #notifications
local stale_finish = usqlp_dadbod.record_query_finish({
  match = "/tmp/a.dbout/DBExecutePost",
  notify = notify,
  now = function()
    return 2000
  end,
})

assert_eq(stale_finish, nil)
assert_eq(#notifications, notification_count)

local overlapping_status = usqlp_dadbod.query_status({
  now = function()
    return 2500
  end,
})
assert_truthy(overlapping_status)
assert_eq(overlapping_status.connection, "usqlp:prod")
assert_eq(overlapping_status.output, "/tmp/b.dbout")

local matching_finish = usqlp_dadbod.record_query_finish({
  match = "/tmp/b.dbout/DBExecutePost",
  notify = notify,
  now = function()
    return 3000
  end,
})
assert_truthy(matching_finish)
assert_eq(usqlp_dadbod.query_status(), nil)

usqlp_dadbod.record_query_start({
  notify = notify,
  now = function()
    return 5000
  end,
})
local cancelled = false
local cancel_result = usqlp_dadbod.cancel_query({
  cancel = function()
    cancelled = true
  end,
  notify = notify,
})
assert_eq(cancel_result, true)
assert_eq(cancelled, true)
assert_eq(usqlp_dadbod.query_status(), nil)
assert_eq(notifications[#notifications].message, "DB query cancelled")
assert_eq(notifications[#notifications].level, vim.log.levels.WARN)

usqlp_dadbod.record_query_start({
  match = "/tmp/cancel.dbout/DBExecutePre",
  notify = notify,
  now = function()
    return 7000
  end,
})
local cancelled_buf
local default_cancel_result = usqlp_dadbod.cancel_query({
  notify = notify,
  exists = function(name)
    if name == "*db#cancel" then
      return 1
    end
    return 0
  end,
  bufnr = function(name)
    if name == "/tmp/cancel.dbout" then
      return 42
    end
    return -1
  end,
  db_cancel = function(buf)
    cancelled_buf = buf
  end,
})
assert_eq(default_cancel_result, true)
assert_eq(cancelled_buf, 42)
assert_eq(usqlp_dadbod.query_status(), nil)

local missing_cancel_result = usqlp_dadbod.cancel_query({
  cancel = false,
  notify = notify,
})
assert_eq(missing_cancel_result, false)
assert_eq(notifications[#notifications].message, "No DB query running")
assert_eq(notifications[#notifications].level, vim.log.levels.INFO)

local original_notify = vim.notify
vim.notify = notify
usqlp_dadbod.reset_query_observability()
usqlp_dadbod.setup_query_observability()
vim.cmd("doautocmd User /tmp/autocmd.dbout/DBExecutePre")
assert_eq(usqlp_dadbod.query_status({ now = function() return 6000 end }).output, "/tmp/autocmd.dbout")
vim.cmd("doautocmd User /tmp/autocmd.dbout/DBExecutePost")
assert_eq(usqlp_dadbod.query_status(), nil)
vim.notify = original_notify
