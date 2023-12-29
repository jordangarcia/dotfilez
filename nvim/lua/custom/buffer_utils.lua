local M = {}

local get_listed_bufs = function()
  local all_bufs = vim.api.nvim_list_bufs()

  return vim.tbl_filter(function(buf)
    local listed = vim.api.nvim_buf_get_option(buf, "buflisted")
    local is_loaded = vim.api.nvim_buf_is_loaded(buf)
    return is_loaded and listed
  end, all_bufs)
end

local get_bufs_to_win = function()
  local api = require "tabby.module.api"
  local tabs = api.get_tabs()

  local bufs_to_win = {}

  for _, tab in ipairs(tabs) do
    local tab_wins = api.get_tab_wins(tab)

    for _, win in ipairs(tab_wins) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      bufs_to_win[bufnr] = bufs_to_win[bufnr] or {}
      table.insert(bufs_to_win[bufnr], {
        win = win,
        tab = tab,
      })
    end
  end

  return bufs_to_win
end

local buf_info = function(buf, bufs_to_win)
  local modified = vim.api.nvim_buf_get_option(buf, "modified")
  local hidden = vim.api.nvim_buf_get_option(buf, "bufhidden")
  return {
    bufnr = buf,
    name = vim.api.nvim_buf_get_name(buf),
    is_loaded = vim.api.nvim_buf_is_loaded(buf),
    is_valid = vim.api.nvim_buf_is_valid(buf),
    filetype = vim.api.nvim_buf_get_option(buf, "filetype"),
    hidden = hidden,
    modified = modified,
    displayed = bufs_to_win[buf],
  }
end

M.ls = function()
  local bufs = get_listed_bufs()
  local bufs_to_win = get_bufs_to_win()

  local res = {}
  for _, buf in ipairs(bufs) do
    res[buf] = buf_info(buf, bufs_to_win)
  end

  return res
end

M.close_buffers = function(check)
  return function()
    local buffers = vim.api.nvim_list_bufs()

    for _, bufnr in ipairs(buffers) do
      local data = {
        ["bufnr"] = bufnr,
        ["filetype"] = vim.api.nvim_buf_get_option(bufnr, "filetype"),
        ["name"] = vim.api.nvim_buf_get_name(bufnr),
      }

      if check(data) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end
  end
end

M.close_help_buffers = M.close_buffers(function(data)
  return data.filetype == "help"
end)

M.close_other_windows = function()
  local api = vim.api

  local curr_tab = api.nvim_get_current_tabpage()
  for _, win in ipairs(api.nvim_list_wins()) do
    local tab = api.nvim_win_get_tabpage(win)
    local n = vim.api.nvim_buf_get_name(api.nvim_win_get_buf(win))
    local ft = vim.api.nvim_buf_get_option(api.nvim_win_get_buf(win), "filetype")

    if api.nvim_get_current_win() ~= win and tab == curr_tab and ft ~= "NvimTree" then
      vim.api.nvim_win_close(win, true)
    end
  end
end

M.close_hidden_buffers = function()
  local bufs = M.ls()
  -- vim.notify(vim.inspect(bufs))

  local closed = 0
  for _, buf in pairs(bufs) do
    if buf.displayed == nil then
      closed = closed + 1
      vim.api.nvim_buf_delete(buf.bufnr, { force = true })
    end
  end

  vim.notify(string.format("Closed %s buffers", closed))
end

M.close_all_fugitive_blame_buffers = function()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if string.find(name, "private/var/folders") then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

M.close_all_fugitive_buffers = function()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if string.find(name, "fugitive://") then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

M.smart_close_window = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local bufs = M.ls()

  local info = bufs[bufnr]

  if not info then
    -- we're not on a file buffer
    vim.cmd [[ q ]]
    return
  end

  if string.find(info.name, "fugitive://") ~= nil then
    print "closing fugitive buf"
    M.close_all_fugitive_buffers()
    return
  end

  local win_bufs = vim.tbl_map(function(win)
    return vim.api.nvim_win_get_buf(win)
  end, wins)
  local other_win_bufs = vim.tbl_filter(function(buf)
    if buf == bufnr then
      return false
    end

    -- only consider bufs that are shown
    if bufs[buf] == nil then
      return false
    end

    local buf_info = bufs[buf]
    return buf_info.filetype ~= "NvimTree" and buf_info.filetype ~= "qf"
  end, win_bufs)

  if #other_win_bufs == 0 then
    vim.cmd [[ tabc ]]
  else
    vim.cmd [[ q ]]
  end
end

M.close_buffer_with_confirm = function()
  if vim.bo.modified then
    local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
    if choice == 1 then -- Yes
      vim.cmd.write()
      vim.api.nvim_buf_delete(0)
    elseif choice == 2 then -- No
      vim.api.nvim_buf_delete(0, { force = true })
    end
  else
    vim.api.nvim_buf_delete(0)
  end
end

return M
