-- Every terminal block in every session, with its foreground process, program
-- status records (OSC 7501) and title. Run by rex/agents.py:
--
--   rex do blocks.lua --json
--   rex do blocks.lua block=block:<uuid> --json   (one block)
--
-- A script only reads sessions it is attached to, so attach to each in turn.
-- The attach result carries the session's view, which saves a session.view call.

local TERMINAL = "com.superlogical.terminal"
local only = rex.args.block

local function block_method(session_id, block_id, method)
  local result = rex.call("block.method", {
    session_id = session_id,
    block_id = block_id,
    method = method,
    args = {},
  })

  return result or {}
end

local function describe(session, view, window, window_index, layer, block)
  return {
    session_id = session.session_id,
    session_label = view.label or session.label,
    window_id = window.window_id,
    window_label = window.label,
    window_index = window_index,
    layer = layer.kind,
    block_id = block.block_id,
    process = block_method(session.session_id, block.block_id, "process"),
    status = block_method(session.session_id, block.block_id, "program_status"),
    title = block_method(session.session_id, block.block_id, "title"),
  }
end

local rows = {}
local list = rex.call("session.list", {}) or {}

for session_index, session in ipairs(list.sessions or {}) do
  local attached, err = rex.session.attach({ session_id = session.session_id })
  if not attached then
    rex.log("warn", "agents: attach failed (session=" .. session.session_id .. "): " .. tostring(err))
  end

  local view = attached and attached.view or {}

  for window_index, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        local is_terminal = block.creator_name == TERMINAL
        local is_wanted = only == nil or only == block.block_id

        if is_terminal and is_wanted then
          local row = describe(session, view, window, window_index, layer, block)
          row.session_index = session_index
          table.insert(rows, row)
        end
      end
    end
  end
end

return rows
