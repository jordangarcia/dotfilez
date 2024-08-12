local function run_python()
  local filename = vim.fn.expand "%:p"
  local cmd = string.format("PYTHONPATH=src pdm run python %s", vim.fn.shellescape(filename))

  -- Check if the buffer already exists
  local buf_name = "Python Output"
  local buf = vim.fn.bufnr(buf_name)

  if buf == -1 then
    -- Create a new buffer if it doesn't exist
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, buf_name)
  else
    -- Clear the existing buffer
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "python-output")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "hide")

  -- Find or create a window for the buffer
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    -- Open the buffer in a new window at the bottom
    vim.cmd "botright split"
    win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
  end

  -- Set window options
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)

  -- Set up the 'q' key binding to close the buffer and window
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

  -- Run the command and capture the output
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.api.nvim_buf_set_option(buf, "modifiable", true)
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
      end
    end,
    on_stderr = function(_, data)
      if data then
        vim.api.nvim_buf_set_option(buf, "modifiable", true)
        vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
      end
    end,
  })
end

return {
  "run-python",
  dev = true,
  lazy = true,
  keys = {
    { "<leader>xr", run_python, desc = "Run python" },
  },
}
