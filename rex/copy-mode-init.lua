-- Viewer setup for rex-copy-mode (~/.config/rex/copy-mode*.lua), passed as its
-- `init` option. nvim runs this with --cmd, before copy-mode-view.lua builds the
-- terminal buffer, so the theme's terminal colors apply to the snapshot.
--
-- nvim starts with -u NONE: nothing from ~/.config/nvim loads except what this
-- file asks for. Kanagawa is vendored in ~/code/dotfilez/nvim/lua/kanagawa and
-- matches the Rex theme's background, so the overlay blends into the pane.
--
-- Claude transcripts (rex/claude_transcript.py) arrive as Markdown and are shown
-- in a normal buffer with soft wrapping and treesitter highlighting instead of
-- the terminal buffer.
--
-- Keys: any yank (y on a selection, yy, yiw, y$, …) copies to the clipboard and
--       closes · Enter on a selection does the same · [[ / ]] previous / next
--       prompt · q or Esc closes · mouse scrolls and selects

local PROMPT = [[\v^\s*❯]]
local HINT = " y copy · [[ ]] prompts · / search · esc close "
local CLOSE_DELAY_MS = 160

local opt = vim.opt

-- Theme ---------------------------------------------------------------------

opt.termguicolors = true

local ok_theme = pcall(function()
  require("kanagawa").setup {}
  require("kanagawa").load()
end)

if not ok_theme then
  pcall(vim.cmd.colorscheme, "habamax")
end

-- Behaviour -----------------------------------------------------------------

opt.mouse = "a"
opt.cursorline = true
opt.cursorlineopt = "line"
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.scrolloff = 4
opt.fillchars = { eob = " " }
opt.shortmess:append "I"

local group = vim.api.nvim_create_augroup("RexCopyMode", { clear = true })

local function close()
  vim.cmd "qa!"
end

-- Every yank goes to the clipboard (the viewer sets clipboard=unnamedplus).
-- Flash what was copied, mark the copy so the viewer shows its "Copied to
-- clipboard" notice, then close and return to the source pane.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    local is_yank = vim.v.event.operator == "y"
    if not is_yank then
      return
    end

    local hl = vim.hl or vim.highlight
    hl.on_yank { higroup = "IncSearch", timeout = CLOSE_DELAY_MS }
    vim.g.rex_copy_mode_copied = true
    vim.defer_fn(close, CLOSE_DELAY_MS)
  end,
})

-- Keys ----------------------------------------------------------------------

local function jump_prompt(flags)
  return function()
    local found = vim.fn.search(PROMPT, flags)
    if found > 0 then
      vim.cmd "normal! 0"
    end
  end
end

vim.keymap.set("n", "q", close, { silent = true, desc = "Close copy mode" })
vim.keymap.set("n", "<Esc>", close, { silent = true, desc = "Close copy mode" })
vim.keymap.set("x", "<CR>", "y", { remap = true, silent = true, desc = "Copy selection and close" })

-- nvim 0.11 gives terminal buffers their own [[ / ]], which follow OSC 133
-- prompt marks. copy-mode strips those marks from the snapshot, so replace
-- them on the viewer's buffer with a search for the zsh prompt character.
local function map_prompt_jumps(buf)
  local opts = { buffer = buf, silent = true }

  vim.keymap.set({ "n", "x" }, "[[", jump_prompt "bW", vim.tbl_extend("force", opts, { desc = "Previous prompt" }))
  vim.keymap.set({ "n", "x" }, "]]", jump_prompt "W", vim.tbl_extend("force", opts, { desc = "Next prompt" }))
end

-- The snapshot has no program behind it, so terminal mode (entered by a mouse
-- click, i or a) only swallows keys. Esc there closes like it does in normal
-- mode, replacing the viewer's own Esc that steps back to normal mode.
local function map_terminal_mode(buf)
  vim.keymap.set("t", "<Esc>", close, { buffer = buf, silent = true, desc = "Close copy mode" })
end

vim.api.nvim_create_autocmd("TermEnter", {
  group = group,
  callback = function()
    vim.schedule(function()
      vim.cmd "stopinsert"
    end)
  end,
})

-- Markdown snapshots ----------------------------------------------------------

-- rex/claude_transcript.py starts its output with this marker. A transcript is
-- prose and Markdown, which a terminal buffer can only hard-wrap at its width,
-- so it gets a normal buffer with soft wrapping and Markdown highlighting.
local MARKDOWN_MARKER = "\27]1337;rex-copy-mode=markdown\7"

local function read_markdown_snapshot()
  local directory = vim.g.rex_copy_mode_directory
  if not directory then
    return nil
  end

  local file = io.open(directory .. "/capture.vt", "rb")
  if not file then
    return nil
  end

  local data = file:read "*a"
  file:close()

  local is_markdown = data:sub(1, #MARKDOWN_MARKER) == MARKDOWN_MARKER
  if not is_markdown then
    return nil
  end

  local body = data:sub(#MARKDOWN_MARKER + 1):gsub("^\n", ""):gsub("\n+$", "")

  return vim.split(body, "\n", { plain = true })
end

local function define_markdown_highlights()
  local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
  local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })

  vim.api.nvim_set_hl(0, "RexCopyPrompt", { fg = title.fg, bg = cursorline.bg, bold = true })
  vim.api.nvim_set_hl(0, "RexCopyTool", { link = "Comment" })
end

-- Prompts ("❯ …" plus their indented continuation lines) and tool calls
-- ("● …") get their own highlights over the Markdown ones.
local function mark_lines(buf, lines)
  local ns = vim.api.nvim_create_namespace "rex_copy_mode_markdown"
  local in_prompt = false

  for index, line in ipairs(lines) do
    local is_prompt_start = line:sub(1, #"❯ ") == "❯ " or line == "❯"
    local is_prompt_rest = in_prompt and line:sub(1, 2) == "  "
    local is_tool = line:sub(1, #"● ") == "● "

    in_prompt = is_prompt_start or is_prompt_rest

    local group = (in_prompt and "RexCopyPrompt") or (is_tool and "RexCopyTool") or nil
    if group then
      vim.api.nvim_buf_set_extmark(buf, ns, index - 1, 0, {
        end_row = index,
        hl_group = group,
        hl_eol = true,
        priority = 200,
      })
    end
  end
end

local function show_markdown(lines, terminal_buf)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  vim.api.nvim_set_current_buf(buf)
  pcall(vim.api.nvim_buf_delete, terminal_buf, { force = true })

  local win = vim.api.nvim_get_current_win()
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].breakindent = true
  vim.wo[win].conceallevel = 2
  vim.wo[win].concealcursor = ""

  local ok_ts, err = pcall(vim.treesitter.start, buf, "markdown")
  if not ok_ts then
    vim.notify("copy mode: no Markdown highlighting: " .. tostring(err), vim.log.levels.WARN)
  end

  define_markdown_highlights()
  mark_lines(buf, lines)

  vim.api.nvim_win_set_cursor(win, { #lines, 0 })
  vim.cmd "normal! zb"

  return buf
end

-- Hint ----------------------------------------------------------------------

-- A one-line hint in the top-right corner until the first key press.
local function show_hint()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { HINT })

  local width = vim.fn.strdisplaywidth(HINT)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = math.max(0, vim.o.columns - width - 1),
    width = width,
    height = 1,
    style = "minimal",
    focusable = false,
    noautocmd = true,
    zindex = 50,
  })
  vim.wo[win].winhighlight = "Normal:Comment"

  local ns = vim.api.nvim_create_namespace "rex_copy_mode_hint"
  vim.on_key(function()
    vim.on_key(nil, ns)
    vim.schedule(function()
      pcall(vim.api.nvim_win_close, win, true)
    end)
  end, ns)
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    -- VimEnter runs after the viewer's -c command, so its terminal buffer exists.
    local buf = vim.api.nvim_get_current_buf()

    local markdown = read_markdown_snapshot()
    if markdown then
      buf = show_markdown(markdown, buf)
    else
      map_terminal_mode(buf)
    end

    map_prompt_jumps(buf)

    -- After the viewer has rendered the snapshot and placed the cursor.
    vim.defer_fn(show_hint, 80)
  end,
})
