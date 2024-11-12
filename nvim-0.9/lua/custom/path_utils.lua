local Path = require "plenary.path"
local os_home = vim.loop.os_homedir()

local M = {}

M.normalize_to_home = function(dir)
  local p = Path:new(dir)

  if vim.startswith(dir, os_home) then
    return "~/" .. p:make_relative(os_home)
  else
    return dir
  end
end

M.normalize = function(dir)
  local p = Path:new(dir)
  local cwd = vim.fn.getcwd()

  if vim.startswith(dir, cwd) then
    return p:make_relative(cwd)
  else
    return M.normalize_to_home(dir)
  end
end

return M
