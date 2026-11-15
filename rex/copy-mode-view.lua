-- Styled copy-mode viewer. Invoked directly as Neovim; no user config or plugins.
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)"))
local common = dofile(root .. "copy-mode-common.lua")
local directory = vim.g.rex_copy_mode_directory
local stat = vim.uv.fs_lstat(directory)
assert(directory:match("/rex%-copy%-mode%-%w+$") and stat and stat.type == "directory"
    and stat.uid == vim.uv.getuid(), "Not an owned Rex copy-mode temporary directory")
local metadata = {}
local own_block = vim.env.REX_BLOCK
local function command(args)
  local result = vim.system(args, { text = true, timeout = 2000 }):wait()
  if result.code ~= 0 then error("Rex operation failed", 0) end
  return result.stdout
end

local function restore_focus()
  if not metadata.session or not metadata.source_block then return end
  local cli = metadata.rex_cli
  if not own_block then
    local identity = vim.json.decode(command({ cli, "whoami", "--json" }))
    own_block = identity.block_id
  end
  if not own_block then return end
  local current = vim.json.decode(command({ cli, "session", "inspect", metadata.session, "--json" }))
  if current.active_window_id ~= metadata.source_window then return end
  for _, window in ipairs(current.windows or {}) do
    if window.window_id == metadata.source_window and window.focused_block_id == own_block then
      command({ cli, "focus", "-s", metadata.session, metadata.source_block })
      if metadata.source_zoomed then command({ cli, "zoom", "-s", metadata.session, metadata.source_block, "--on" }) end
      return true
    end
  end
end

local function show_copied_message()
  local bounds = metadata.source_bounds or { 0, 0, 1, 1 }
  local message = "Copied to clipboard"
  -- Estimate window-relative cell size from the viewer's grid and source rect.
  -- Use just the floating pane's title; no terminal output or extra editor.
  local width = math.min(0.9, (#message + 8) * bounds[3] / vim.o.columns)
  local height = math.min(0.12, 1.6 * bounds[4] / vim.o.lines)
  local layer = {
    session_id = metadata.session, window_id = metadata.source_window,
    bounds = { (1 - width) / 2, 1 - height, width, height }, focus = false,
    layout = { block = {
      flavor = "com.superlogical.terminal.shell", label = message,
      options = {
        shell = "none", command = { "sleep", tostring(metadata.toast_seconds) },
        size = { columns = #message + 8, rows = 1 },
        exit = { on_completion = true, quick_exit_threshold_ms = 0 },
      },
    } },
  }
  command({ metadata.rex_cli, "api", "call", "-s", metadata.session, "session.new_layer", vim.json.encode(layer) })
end

-- Install before reading any payload, so startup errors also clean up on exit.
vim.api.nvim_create_autocmd("VimLeavePre", {
  once = true,
  callback = function()
    local ok, restored = pcall(restore_focus) -- Closed source/server must not prevent cleanup.
    if ok and restored and vim.g.rex_copy_mode_copied and metadata.toast_seconds > 0 then
      pcall(show_copied_message) -- Best effort; clipboard and cleanup must not depend on it.
    end
    vim.fn.delete(directory, "rf")
  end,
})

local function read_file(path)
  local file = assert(io.open(path, "rb"))
  local data = file:read("*a")
  file:close()
  return data
end

local function start()
  metadata = vim.json.decode(read_file(directory .. "/meta.json"))
  local snapshot = common.sanitize_vt(read_file(directory .. "/capture.vt"))

  vim.opt.termguicolors = true
  vim.opt.clipboard = "unnamedplus"
  vim.opt.titlestring = metadata.title:gsub("%%", "%%%%")
  vim.opt.titlelen = 0
  vim.opt.title = true
  -- No chrome: all terminal rows remain available for the original snapshot.
  vim.opt.laststatus = 0
  vim.opt.cmdheight = 0
  vim.opt.showtabline = 0
  vim.opt.showmode = false
  vim.opt.showcmd = false
  vim.opt.ruler = false
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = "no"
  vim.opt.foldcolumn = "0"
  vim.opt.scrollback = 100000
  vim.opt.modeline = false
  vim.opt.swapfile = false
  vim.opt.shadafile = "NONE"

  local buffer = vim.api.nvim_get_current_buf()
  local channel = vim.api.nvim_open_term(buffer, { force_crlf = true, on_input = function() end })
  assert(channel ~= 0, "Could not create the internal terminal")
  vim.bo[buffer].bufhidden = "wipe"
  vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = buffer, silent = true })
  -- Visual-only: copy the exact character/line/block selection, then close the
  -- disposable viewer. Explicit '+' register targets the system clipboard.
  if metadata.copy_key then
    vim.keymap.set("x", metadata.copy_key, [["+y<Cmd>lua vim.g.rex_copy_mode_copied = true<CR><Cmd>qa!<CR>]], {
      buffer = buffer, silent = true, desc = "Copy selection and return to source pane",
    })
  end
  for offset = 1, #snapshot, 65536 do
    vim.api.nvim_chan_send(channel, snapshot:sub(offset, offset + 65535))
  end
  vim.cmd.stopinsert()
  -- Terminal scrollback is flushed by Neovim's refresh timer.
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buffer) then
      vim.cmd.stopinsert()
      vim.api.nvim_win_set_cursor(0, { math.max(1, vim.fn.prevnonblank("$")), 0 })
      vim.cmd("normal! zb")
    end
  end, 50)
end

local ok = pcall(start)
if not ok then
  -- Fail closed instead of leaving a half-rendered pager or printing payloads.
  vim.cmd("cquit 1")
end
