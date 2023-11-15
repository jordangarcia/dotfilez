local M = {}
local api = vim.api
local fn = vim.fn

local isBufValid = function(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted
end

local function new_hl(group1, group2)
  local fg = fn.synIDattr(fn.synIDtrans(fn.hlID(group1)), "fg#")
  local bg = fn.synIDattr(fn.synIDtrans(fn.hlID(group2)), "bg#")
  api.nvim_set_hl(0, "Tbline" .. group1 .. group2, { fg = fg, bg = bg })
  return "%#" .. "Tbline" .. group1 .. group2 .. "#"
end

local winbar_file = function()
  -- local name = vim.fn.expand('%')

  local win = vim.api.nvim_get_current_win()
  local nr = vim.api.nvim_win_get_buf(win)
  local ft = vim.api.nvim_buf_get_option(nr, "filetype")
  if ft == "gitcommit" or ft == "help" then
    return ""
  end

  local tail = fn.fnamemodify(api.nvim_buf_get_name(nr), ":t")
  local head = fn.fnamemodify(api.nvim_buf_get_name(nr), ":h")
  local base = fn.fnamemodify(head, ":.")

  -- print("head: " .. head .. "\ntail: " .. tail .. "\nbase:" .. base)
  local icon2 = ""
  -- print("icons?" .. vim.inspect(devicons_present))
  if true and devicons_present then
    local icon, icon_hl = devicons.get_icon(tail)

    if not icon then
      icon = "󰈚"
      icon_hl = "DevIconDefault"
    end

    icon2 = (
      api.nvim_get_current_buf() == nr and new_hl(icon_hl, "TbLineBufOn") .. " " .. icon
      or new_hl(icon_hl, "TbLineBufOff") .. " " .. icon
    )
    -- print("whats my icon" .. icon)
    -- check for same buffer names under different dirs
  end

  -- filename only
  local name = (#api.nvim_buf_get_name(nr) ~= 0) and fn.fnamemodify(api.nvim_buf_get_name(nr), ":t") or ""
  local name = (#api.nvim_buf_get_name(nr) ~= 0) and api.nvim_buf_get_name(nr) or ""
  local Path = require "plenary.path"
  name = Path:new(name):normalize(vim.fn.getcwd())

  if name == "" then
    return ""
  end

  -- if name contains NvimTree
  if string.find(name, "NvimTree") then
    return ""
  end

  -- local file_name = add_fileInfo(name, nr)
  local modified = " %-m"
  -- local right_align = "%="
  local right_align = ""

  local hl = "%#Comment#"

  return string.format(
    "%s%s %s%s%s%s%s",
    "%=" .. "",
    -- "%=" .. icon2,
    "%#WinBarPath#",
    base .. "/",
    "%#WinBar#",
    tail,
    "%#WinBar#",
    modified
  )
end

M.show_winbar = function()
  local value = winbar_file()
  if not value then
    return
  end

  local status_ok, _ = pcall(vim.api.nvim_set_option_value, "winbar", value, { scope = "local" })
  if not status_ok then
    return
  end
end

M.setup = function()
  api.nvim_set_hl(0, "WinBarPath", { fg = "#4c4c55" })

  vim.api.nvim_create_autocmd({ "DirChanged", "BufWinEnter", "BufFilePost", "InsertEnter", "BufWritePost" }, {
    callback = function()
      M.show_winbar()
    end,
  })
end

return M
