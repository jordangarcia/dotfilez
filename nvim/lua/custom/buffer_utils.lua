local M = {}

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

local close_all_fugitive_buffers = function()
  local bufs = vim.api.nvim_list_bufs()
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if string.find(name, "fugitive://") then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

M.smart_close_buffer = function()
  local ft = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "filetype")

  local filepath = vim.fn.expand "%"
  local is_fugitive = string.find(filepath, "fugitive://") ~= nil
  -- fugitive blame shows up like this
  local is_private = string.find(filepath, "private/var/folders") ~= nil

  if is_fugitive then
    close_all_fugitive_buffers()
  elseif ft == "help" or ft == "qf" or is_private then
    vim.cmd "q"
  else
    require("nvchad.tabufline").close_buffer()
  end
end

return M
