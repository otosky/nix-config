local function uuid()
  local id, _ = vim.fn.system("uuidgen"):gsub("\n", "")
  return id
end

return {
  s({
    trig = "uuid",
    name = "UUID",
    dscr = "Generate a unique UUID",
  }, {
    d(1, function()
      return sn(nil, i(1, uuid()))
    end),
  }),
}
