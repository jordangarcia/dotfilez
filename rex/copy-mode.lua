-- Rex copy-mode: styled, keyboard-only scrollback in a disposable Neovim overlay.
-- From https://github.com/CJNE/rex-copy-mode at c749d98 (MIT, copy-mode-LICENSE).
-- Local additions: the `init` and `snapshot` options here, and trailing blank
-- cell trimming in copy-mode-common.lua.
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)"), "Load copy-mode.lua from a file")
local common = dofile(root .. "copy-mode-common.lua")
local M = {}
local CHUNK = 983040

local function checked(result, err)
  if not result then error(err or "Rex operation failed", 0) end
  return result
end

local function exec(argv)
  local result = checked(rex.exec(argv, { timeout = 5 }))
  if not result.ok then error("Copy-mode helper failed: " .. argv[1], 0) end
  return result
end

local function executable(name)
  -- Rex's terminal launcher can have a narrower PATH than rex.exec. Resolve
  -- once at setup, not on every invocation, and never invoke a shell.
  local result, err = rex.exec({ "which", name }, { timeout = 5 })
  assert(result and result.ok, "Cannot find " .. name .. "; configure an executable path. " .. (err or ""))
  return assert(result.stdout:match("[^\r\n]+"), "Empty executable lookup: " .. name)
end

local function block_call(ctx, method, args)
  return checked(rex.block.call("com.superlogical.terminal", method, {
    session_id = ctx.session_id, block_id = ctx.block_id, args = args or {},
  }))
end

local function remove_snapshot(directory)
  -- The directory is made by mktemp in this action, never taken from user input.
  os.remove(directory .. "/capture.vt")
  os.remove(directory .. "/meta.json")
  pcall(rex.exec, { "rmdir", directory }, { timeout = 2 })
end

local function write_text(directory, text)
  local file = assert(io.open(directory .. "/capture.vt", "wb"))
  local written, err = file:write(text:sub(-1) == "\n" and text or text .. "\n")
  file:close()
  assert(written, err)
end

local function write_capture(ctx, directory, snapshot)
  -- A snapshot function can supply the text instead, e.g. a transcript for a
  -- program on the alternate screen. nil, "" or an error falls back to the pane.
  if snapshot then
    local ok, text = pcall(snapshot, ctx)
    if not ok then
      rex.log("warn", "copy-mode: snapshot failed, using the pane capture: " .. tostring(text))
    elseif type(text) == "string" and text ~= "" then
      write_text(directory, text)
      return
    end
  end

  local part = block_call(ctx, "format", {
    format = "vt", trim = true, unwrap = true, max_bytes = CHUNK,
  })
  local file = assert(io.open(directory .. "/capture.vt", "wb"))
  local ok, err = pcall(function()
    local offset, blob_id, tail = 0, part.id, ""
    local content = part.content
    while true do
      if #content == 0 and offset == 0 then error("Rex returned an empty capture", 0) end
      assert(file:write(content))
      offset, tail = offset + #content, content:sub(-1)
      if offset > 128 * 1024 * 1024 then error("Rex capture exceeds 128 MiB", 0) end
      if not blob_id or part.eof == true or (part.total and offset >= part.total) then break end
      part = block_call(ctx, "blob_read", { id = blob_id, offset = offset, max_bytes = CHUNK })
      content = part.data
      if #content == 0 then error("Rex returned an incomplete capture", 0) end
    end
    if tail ~= "\n" then assert(file:write("\n")) end
  end)
  file:close()
  if not ok then error(err, 0) end
end

function M.setup(user)
  -- init: absolute path to a Lua file the viewer runs before it starts, for a theme and keymaps.
  -- It runs before the terminal buffer exists, so its terminal colors apply to the snapshot.
  -- snapshot: function(ctx) returning the text to show instead of the pane's capture, or nil.
  local options = {
    key = "ctrl+a>enter", copy_key = "<CR>", nvim = "nvim", rex = "rex", toast_seconds = 1.2,
    init = false, snapshot = false,
  }
  for key, value in pairs(user or {}) do
    assert(options[key] ~= nil, "Unknown copy-mode option: " .. tostring(key))
    options[key] = value
  end
  for _, key in ipairs({ "nvim", "rex" }) do
    assert(type(options[key]) == "string" and options[key] ~= "", key .. " must be an executable name or path")
  end
  for _, key in ipairs({ "key", "copy_key", "init" }) do
    assert(options[key] == false or (type(options[key]) == "string" and options[key] ~= ""), key .. " must be a shortcut or false")
  end
  assert(options.snapshot == false or type(options.snapshot) == "function", "snapshot must be a function or false")
  assert(type(options.toast_seconds) == "number" and options.toast_seconds >= 0
      and options.toast_seconds < math.huge, "toast_seconds must be a finite nonnegative number")
  options.nvim, options.rex = executable(options.nvim), executable(options.rex)

  rex.action{
    name = "copy_mode",
    title = "Copy Mode",
    description = "Keyboard-only search, selection and clipboard copy; :q returns to the source pane",
    category = "Pane",
    keywords = "copy mode scrollback vim neovim capture",
    run = function(ctx, args)
      if not ctx.session_id or not ctx.block_id then error("Copy-mode needs a focused terminal pane", 0) end
      local source = checked(rex.session.describe_block{ session_id = ctx.session_id, block_id = ctx.block_id })
      if source.block.creator_name ~= "com.superlogical.terminal" then error("Copy-mode needs a terminal pane", 0) end
      local window_id = source.block.window_id
      if not window_id then error("Source pane is not in a window", 0) end
      local view = checked(rex.session.view{ session_id = ctx.session_id })
      local bounds, source_zoomed = common.pane_bounds(view, window_id, ctx.block_id)
      local title = common.title(block_call(ctx, "title").title or "", source.block.label)
      local temporary_root = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
      local directory = exec({ "mktemp", "-d", temporary_root .. "/rex-copy-mode-XXXXXXXX" }).stdout:gsub("%s+$", "")
      local opened = false
      local ok, result = pcall(function()
        write_capture(ctx, directory, options.snapshot)
        local metadata = {
          title = title, session = ctx.session_id,
          source_block = ctx.block_id, source_window = window_id, source_zoomed = source_zoomed,
          source_bounds = bounds,
          rex_cli = options.rex, copy_key = options.copy_key, toast_seconds = options.toast_seconds,
        }
        local encoded = checked(rex.json.encode(metadata))
        local file = assert(io.open(directory .. "/meta.json", "wb"))
        local written, write_err = file:write(encoded)
        file:close()
        assert(written, write_err)
        -- Parent is already 0700; make both files 0600 before handing off.
        exec({ "chmod", "600", directory .. "/capture.vt", directory .. "/meta.json" })
        local command = {
          options.nvim, "-u", "NONE", "-i", "NONE", "-n", "--cmd", "set nomodeline",
          "--cmd", "lua vim.g.rex_copy_mode_directory = " .. string.format("%q", directory),
        }
        if options.init then
          table.insert(command, "--cmd")
          table.insert(command, "lua dofile(" .. string.format("%q", options.init) .. ")")
        end
        table.insert(command, "-c")
        table.insert(command, "lua dofile(" .. string.format("%q", root .. "copy-mode-view.lua") .. ")")
        local layer = checked(rex.session.new_layer{
          session_id = ctx.session_id, window_id = window_id, bounds = bounds, focus = true,
          layout = rex.layout.block{
            flavor = "com.superlogical.terminal.shell", label = title,
            options = {
              shell = "none",
              command = command,
              exit = { on_completion = true, quick_exit_threshold_ms = 0 },
            },
          },
        })
        opened = true -- Neovim now owns cleanup, including startup-error exits.
        if ctx.client_id and (ctx.origin == "key" or ctx.origin == "palette") then
          rex.client.queue("session.select", { session_id = ctx.session_id, window_id = window_id })
        end
        return layer
      end)
      if not opened then remove_snapshot(directory) end
      if not ok then error(result, 0) end
      return result
    end,
  }

  if options.key then rex.bind(options.key, "copy_mode") end
  return M
end

return M
