-- Shared pure Lua 5.1 helpers; usable in both Rex and Neovim (and unit tests).
local M = {}
local ESC = string.char(27)

local function trim(text)
  return text:match("^%s*(.-)%s*$")
end

function M.title(terminal_title, label)
  label = label or "Terminal"
  local generic = label == "" or label == "shell" or label == "terminal"
      or label == "Terminal" or label:match("^Block %x%x%x%x%x%x%x%x$")
  local base = (generic and terminal_title ~= "" and terminal_title) or label
  base = trim((base or ""):gsub("\194[\128-\159]", ""):gsub("[%z\1-\31\127]", ""))
  if base == "" then base = "Terminal" end
  local prefix = "(copy-mode) "
  -- Avoid stacking markers when opening copy-mode from another viewer.
  while base:sub(1, #prefix) == prefix do base = trim(base:sub(#prefix + 1)) end
  local limit = 128 - #prefix
  -- Don't split a UTF-8 codepoint when enforcing Rex's label length limit.
  if #base > limit then
    while limit > 0 and base:byte(limit + 1) >= 128 and base:byte(limit + 1) <= 191 do
      limit = limit - 1
    end
    base = trim(base:sub(1, limit))
  end
  return prefix .. (base ~= "" and base or "Terminal")
end

function M.sanitize_vt(text)
  local c1 = { [144] = "P", [152] = "X", [155] = "[", [156] = "\\", [157] = "]", [158] = "^", [159] = "_" }
  text = text:gsub("\194[\128-\159]", function(pair)
    local suffix = c1[pair:byte(2)]
    return suffix and ESC .. suffix or ""
  end)
  local output, i = {}, 1
  while i <= #text do
    -- Copy text in spans, not one list entry per byte of a large snapshot.
    local first, last = text:find("[^%z\1-\8\11\12\14-\31\127]+", i)
    if first == i then
      output[#output + 1] = text:sub(first, last)
      i = last + 1
    elseif text:byte(i) == 27 then
      local start, kind = i, text:sub(i + 1, i + 1)
      i = i + 2
      if kind == "[" then
        local final = text:find("[@-~]", i)
        if not final then break end
        if text:sub(final, final) == "m" and text:sub(i, final - 1):match("^[0-9;:]*$") then
          output[#output + 1] = text:sub(start, final)
        end
        i = final + 1
      elseif kind ~= "" and ("]PX^_"):find(kind, 1, true) then
        local stop = text:find(ESC .. "\\", i, true)
        local bell = kind == "]" and text:find("\7", i, true) or nil
        if bell and (not stop or bell < stop) then i = bell + 1
        elseif stop then i = stop + 2
        else break end
      elseif kind >= " " and kind <= "/" then
        while i <= #text and text:byte(i) >= 32 and text:byte(i) <= 47 do i = i + 1 end
        i = i + 1
      end
    else
      i = i + 1 -- Drop other C0 controls. Never forward OSC/DCS or device queries.
    end
  end
  local text_out = table.concat(output):gsub("\r\n", "\n"):gsub("\r", "\n")
  return (text_out:gsub("[^\n]+", M.trim_line))
end

-- Programs such as Neovim pad every line to the pane width with styled spaces,
-- and the overlay is a few columns narrower than the pane (its title bar and
-- border), so padded lines would wrap onto a second row. Drop trailing blank
-- cells and the styles around them, then reset so no background bleeds on.
function M.trim_line(line)
  local trimmed = line
  repeat
    local before = trimmed
    trimmed = trimmed:gsub(" +$", "")
    trimmed = trimmed:gsub(ESC .. "%[[0-9;:]*m$", "")
  until trimmed == before

  if trimmed == line then
    return line
  end

  return trimmed .. ESC .. "[0m"
end

function M.find_rect(node, block_id)
  if not node then return nil end
  if node.block_id == block_id then return node.rect end
  if node.split then
    return M.find_rect(node.split.before, block_id) or M.find_rect(node.split.after, block_id)
  end
end

function M.pane_bounds(view, window_id, block_id)
  for _, window in ipairs(view.windows or {}) do
    if window.window_id == window_id then
      if window.zoomed_block_id == block_id then return { 0, 0, 1, 1 }, true end
      for _, layer in ipairs(window.layers or {}) do
        local rect = M.find_rect(layer.layout, block_id)
        if rect then
          -- Node rectangles already include floating-layer offsets.
          local x, y = math.max(0, rect[1]), math.max(0, rect[2])
          return { x, y, math.min(rect[3], 1 - x), math.min(rect[4], 1 - y) }, false
        end
      end
    end
  end
  error("Cannot locate the source pane in Rex's current layout", 0)
end

return M
