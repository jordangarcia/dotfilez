local M = {}

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

M.close_non_file_buffers = function()
  local bufs = vim.t.bufs

  if not bufs then
    return {}
  end

  for i, nr in ipairs(bufs) do
    local n = vim.api.nvim_buf_get_name(nr)
    local ft = vim.api.nvim_buf_get_option(nr, "filetype")
    if ft == "" then
      vim.api.nvim_buf_delete(nr, { force = true })
    end
  end
end

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
  local buffers = vim.api.nvim_list_bufs()

  local api = vim.api

  local closed = 0
  local non_hidden_buffer = {}
  for _, win in ipairs(api.nvim_list_wins()) do
    table.insert(non_hidden_buffer, api.nvim_win_get_buf(win))
  end
  for _, buf in ipairs(buffers) do
    -- check if index exists in tab
    local is_hidden = not vim.tbl_contains(non_hidden_buffer, buf)
    -- local listed = vim.api.nvim_buf_get_option(buf, 'buflisted')
    -- local name = vim.api.nvim_buf_get_name(buf) -- Get the full path of the buffer
    local modified = vim.api.nvim_buf_get_option(buf, "modified") -- Check if the buffer has been modified
    -- local line_count = vim.api.nvim_buf_line_count(buf) -- Get the total number of lines in the buffer

    if is_hidden and not modified then
      closed = closed + 1
      vim.api.nvim_buf_delete(buf, { force = true })
    end

    print(string.format("Closed %s buffers", closed))
    vim.cmd "redrawtabline"
  end
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

local is_shown_elsewhere = function(file)
  local curr_window = vim.api.nvim_get_current_win()

  -- get all windows in current tab
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local win_file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if win ~= curr_window and win_file == file then
      -- is open in another tab
      -- close the current window
      return true
    end
  end

  return false
end

-- check if its last window on tab, excluding nvim tree
local is_last_window = function()
  local curr_window = vim.api.nvim_get_current_win()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local num_wins = #wins
  for _, win in ipairs(wins) do
    local ft = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype")
    if win == curr_window or ft == "NvimTree" then
      num_wins = num_wins - 1
    end
  end

  return num_wins == 0
end

M.smart_close_window = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(0)
  local curr_window = vim.api.nvim_get_current_win()
  -- if there is only one window, and only buffer
  if is_last_window() then
    -- close the buffer and either show a new buffer or newfile
    require("nvchad.tabufline").close_buffer()
    return
  end

  if is_shown_elsewhere(file) then
    vim.api.nvim_win_close(curr_window, true)
  else
    vim.api.nvim_buf_delete(bufnr, {})
  end
end

-- this function does its best to close the buffer and not change the layout
-- if the buffer is open in another window, it will cycle to the previous
-- if only one buffer is shown in multiple windows it will
M.smart_close_buffer = function()
  local filepath = vim.fn.expand "%"
  local ft = vim.api.nvim_buf_get_option(0, "filetype")
  local is_fugitive = string.find(filepath, "fugitive://") ~= nil
  -- fugitive blame shows up like this
  local is_private = string.find(filepath, "private/var/folders") ~= nil
  if is_fugitive then
    M.close_all_fugitive_buffers()
    return
  elseif ft == "help" or ft == "qf" or is_private then
    vim.cmd "q"
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(0)

  local curr_buf_ind = require("nvchad.tabufline").getBufIndex(bufnr)
  -- if its shown somewhere else goto prev buf
  if is_shown_elsewhere(file) then
    if #vim.t.bufs > 1 then
      -- goto other buffer
      local offset = curr_buf_ind == #vim.t.bufs and -1 or 1
      vim.cmd("b" .. vim.t.bufs[curr_buf_ind + offset])
    else
      -- if the only buffer we have open is open in more than one window, just close window
      vim.api.nvim_win_close(vim.api.nvim_get_current_win(), true)
    end
    return
  end

  require("nvchad.tabufline").close_buffer()
end

return M
