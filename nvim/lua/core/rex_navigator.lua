-- ctrl+h/j/k/l across nvim splits and terminal panes.
--
-- In Rex (REX_BLOCK is set), move between nvim windows and hand off to Rex at
-- the edge with `rex focus`. Rex sends ctrl+h/l here only while nvim is the
-- pane's foreground program, see the "navigate" action in ~/.config/rex/init.lua.
-- Everywhere else, vim-kitty-navigator does the same for kitty.

local M = {}

local WINCMD = {
  left = "h",
  down = "j",
  up = "k",
  right = "l",
}

local KITTY_COMMAND = {
  left = "KittyNavigateLeft",
  down = "KittyNavigateDown",
  up = "KittyNavigateUp",
  right = "KittyNavigateRight",
}

local function in_rex()
  return vim.env.REX_BLOCK ~= nil and vim.env.REX_BLOCK ~= ""
end

local function rex_focus(direction)
  local ok, err = pcall(vim.system, { "rex", "focus", direction }, { text = true }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("rex focus " .. direction .. " failed: " .. (result.stderr or ""), vim.log.levels.WARN)
      end)
    end
  end)

  if not ok then
    vim.notify("rex focus " .. direction .. " failed: " .. tostring(err), vim.log.levels.WARN)
  end
end

function M.navigate(direction)
  if not in_rex() then
    vim.cmd(KITTY_COMMAND[direction])
    return
  end

  local before = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. WINCMD[direction])

  local at_edge = vim.api.nvim_get_current_win() == before
  if at_edge then
    rex_focus(direction)
  end
end

return M
