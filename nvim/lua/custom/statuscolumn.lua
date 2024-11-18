local M = {}

local hl = function(hlname)
  return "%#" .. hlname .. "#"
end

local left_pad = function(text, width)
  local pad = string.rep(" ", width - vim.fn.strchars(text))
  return pad .. text
end

local line_no_only = function()
  local win = vim.g.statusline_winid
  local is_num = vim.wo[win].number
  local is_relnum = vim.wo[win].relativenumber
  if (is_num or is_relnum) and vim.v.virtnum == 0 then
    if vim.v.relnum == 0 then -- the current line
      -- current line should be left aligned
      return " " .. (is_num and "%l" or "%r") .. " "
    else
      return "%=" .. (is_relnum and "%r" or "%l") .. " "
    end
  end
  return ""
end

local line_no = function(diag_hl, text)
  local win = vim.g.statusline_winid
  local is_num = vim.wo[win].number
  local is_relnum = vim.wo[win].relativenumber
  if (is_num or is_relnum) and vim.v.virtnum == 0 then
    local num_text = text
    if not num_text then
      if vim.v.relnum == 0 then -- the current line
        num_text = is_num and "%l" or "%r"
      else
        num_text = is_relnum and "%r" or "%l"
      end
    end

    if vim.v.relnum == 0 then -- the current line
      -- current line should be left aligned
      return table.concat({
        hl(diag_hl and diag_hl or "CursorLineNr"),
        "%=",
        num_text,
      }, "")
    else
      return table.concat({
        hl(diag_hl and diag_hl or "LineNr"),
        "%=",
        num_text,
      }, "")
      -- components[2] = output {
      --   -- left = true,
      --   width = 3,
      --   hl = "StatusColumn",
      -- }
    end
  end
  return hl "StatusColumn" .. ""
end

---@param obj {text: string, hl: string, width: number, left?: boolean}
local output = function(obj)
  local left = obj.left or false
  local pad = string.rep(" ", obj.width - vim.fn.strchars(obj.text))
  local text = left and pad .. obj.text or obj.text .. pad
  parts = {
    hl(obj.hl),
    text,
    -- right and "%=" or "",
  }

  return table.concat(parts, "")
end

---@alias Sign {name:string, text:string, texthl:string, priority:number}
--
function M.statuscolumn()
  local disabled_fts = { "gitcommit", "NvimTree", "dapui_watches", "dapui_stacks", "dapui_breakpoints", "dapui_scopes" }

  local win = vim.g.statusline_winid
  local buf = vim.api.nvim_win_get_buf(win)
  local is_file = vim.bo[buf].buftype == ""
  local ft = vim.bo[buf].filetype

  -- local line_no_enabled = vim.wo[win].number or vim.wo[win].rnu
  -- if not line_no_enabled then
  --   return ""
  -- end

  if vim.tbl_contains(disabled_fts, ft) then
    return line_no_only()
  end

  local show_signs = vim.wo[win].signcolumn ~= "no"

  local components = { "", "", "" } -- left, middle, right

  local diag
  local line_hl
  local line_text = nil

  if show_signs then
    ---@type Sign?,Sign?,Sign?
    local git = {}
    for _, s in ipairs(M.get_signs(buf, vim.v.lnum)) do
      if s.name and s.name:find "GitSign" then
        git = s
      elseif s.name and s.name:find "Dap" then
        line_hl = "DapSignColumn"
        line_text = s.text
      else
        print("sign: " .. s.name)
        line_hl = s.name
        -- dont change text for diagnostic
        -- line_text = vim.v.lnum
      end
    end

    -- components[1] = hl "StatusColumn" .. ""
    components[1] = " "
    local line = "│"
    local thick = "▎"

    local git_text = " "
    if git and git.text then
      git_text = string.sub(git.text, 1, 1) == "|" and line or ""
    end

    components[3] = output {
      text = git_text,
      left = true,
      hl = git and git.texthl or "LineNr",
      width = 1,
    }
  end

  components[2] = line_no(line_hl, line_text)

  return table.concat(components, "")
end

-- Returns a list of regular and extmark signs sorted by priority (low to high)
---@return Sign[]
---@param buf number
---@param lnum number
function M.get_signs(buf, lnum)
  -- Get regular signs
  ---@type Sign[]
  local signs = vim.tbl_map(function(sign)
    ---@type Sign
    local ret = vim.fn.sign_getdefined(sign.name)[1]
    if not ret then
      return
    end
    ret.priority = sign.priority
    return ret
  end, vim.fn.sign_getplaced(buf, { group = "*", lnum = lnum })[1].signs)

  -- Get extmark signs
  local extmarks = vim.api.nvim_buf_get_extmarks(
    buf,
    -1,
    { lnum - 1, 0 },
    { lnum - 1, -1 },
    { details = true, type = "sign" }
  )

  for _, extmark in pairs(extmarks) do
    signs[#signs + 1] = {
      name = extmark[4].sign_hl_group or "",
      text = extmark[4].sign_text,
      texthl = extmark[4].sign_hl_group,
      priority = extmark[4].priority,
    }
  end

  -- Sort by priority
  table.sort(signs, function(a, b)
    return (a.priority or 0) < (b.priority or 0)
  end)

  local res = vim.tbl_filter(function(sign)
    return sign.name ~= "DiagnosticSignInfo" and sign.name ~= "DiagnosticSignHint"
  end, signs)

  -- uncomment to debug what signs are showing
  -- local cursor_lnum = vim.api.nvim_win_get_cursor(0)[1]
  -- if #res > 0 then
  --   if cursor_lnum == lnum then
  --     vim.notify(vim.inspect(res))
  --   end
  -- end
  return res
end

---@return Sign?
---@param buf number
---@param lnum number
function M.get_mark(buf, lnum)
  local marks = vim.fn.getmarklist(buf)
  vim.list_extend(marks, vim.fn.getmarklist())
  for _, mark in ipairs(marks) do
    if mark.pos[1] == buf and mark.pos[2] == lnum and mark.mark:match "[a-zA-Z]" then
      return { text = mark.mark:sub(2), texthl = "DiagnosticHint" }
    end
  end
end

function M.foldtext()
  local ok = pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
  local ret = ok and vim.treesitter.foldtext and vim.treesitter.foldtext()
  if not ret or type(ret) == "string" then
    ret = { { vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, false)[1], {} } }
  end
  table.insert(ret, { " " .. require("lazyvim.config").icons.misc.dots })

  if not vim.treesitter.foldtext then
    return table.concat(
      vim.tbl_map(function(line)
        return line[1]
      end, ret),
      " "
    )
  end
  return ret
end

function M.fg(name)
  ---@type {foreground?:number}?
  ---@diagnostic disable-next-line: deprecated
  local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name }) or vim.api.nvim_get_hl_by_name(name, true)
  ---@diagnostic disable-next-line: undefined-field
  local fg = hl and (hl.fg or hl.foreground)
  return fg and { fg = string.format("#%06x", fg) } or nil
end

M.skip_foldexpr = {} ---@type table<number,boolean>
local skip_check = assert(vim.loop.new_check())

function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()

  -- still in the same tick and no parser
  if M.skip_foldexpr[buf] then
    return "0"
  end

  -- don't use treesitter folds for non-file buffers
  if vim.bo[buf].buftype ~= "" then
    return "0"
  end

  -- as long as we don't have a filetype, don't bother
  -- checking if treesitter is available (it won't)
  if vim.bo[buf].filetype == "" then
    return "0"
  end

  local ok = pcall(vim.treesitter.get_parser, buf)

  if ok then
    return vim.treesitter.foldexpr()
  end

  -- no parser available, so mark it as skip
  -- in the next tick, all skip marks will be reset
  M.skip_foldexpr[buf] = true
  skip_check:start(function()
    M.skip_foldexpr = {}

    skip_check:stop()
  end)
  return "0"
end

return M
