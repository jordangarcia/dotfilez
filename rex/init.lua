-- Rex keybindings migrated from tmux, Ghostty, kitty and WezTerm.

-- tmux (~/.config/tmux/tmux.conf), prefix ctrl+f
rex.bind("ctrl+f>ctrl+f", "pane.send_key", { key = "ctrl+f" })
rex.bind("ctrl+f>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+f>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+f>g", "client.tab.new")
rex.bind("ctrl+f>shift+g", "client.tab.new")
rex.bind("ctrl+f>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+f>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+f>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+f>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+f>r", "client.config.reload")
rex.bind("ctrl+f>x", "pane.close")
rex.bind("ctrl+f>c", "client.tab.new")
rex.bind("ctrl+f>shift+c", "client.tab.new")
rex.bind("ctrl+f>,", "client.tab.rename")

-- Ghostty (~/.config/ghostty/config)
rex.bind("ctrl+shift+p", "pane.paste")
rex.bind("shift+up", "client.prompt.previous")
rex.bind("shift+down", "client.prompt.next")

-- kitty (~/.config/kitty/kitty.conf), kitty_mod = ctrl+shift
rex.bind("ctrl+shift+enter", "pane.split", { direction = "right" })
rex.bind("ctrl+shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+shift+z", "pane.zoom")
rex.bind("ctrl+shift+=", "pane.zoom")
rex.bind("cmd+9", "client.tab.goto", { index = 9 })
rex.bind("alt+cmd+h", "client.tab.previous")
rex.bind("alt+cmd+l", "client.tab.next")
rex.bind("alt+cmd+left", "client.tab.previous")
rex.bind("alt+cmd+right", "client.tab.next")
rex.bind("ctrl+alt+cmd+left", "client.tab.move", { direction = "backward" })
rex.bind("ctrl+alt+cmd+right", "client.tab.move", { direction = "forward" })
rex.bind("ctrl+shift+k", "client.palette.toggle")
rex.bind("ctrl+alt+cmd+5", "client.config.reload")

-- kitty sends \x1b[23~ and \x1b[24~, the F11 and F12 sequences, for nvim folds.
rex.bind("ctrl+-", "pane.send_key", { key = "f11" })
rex.bind("ctrl+=", "pane.send_key", { key = "f12" })
rex.bind("shift+cmd+e", "pane.send_key", { key = "alt+shift+e" })

-- \e\r is alt+enter; Claude Code reads it as a newline.
rex.bind("shift+enter", "pane.send_key", { key = "alt+enter" })

-- WezTerm (~/.config/wezterm/wezterm.lua), hyper = ctrl+shift
rex.bind("ctrl+shift+f5", "client.config.reload")
rex.bind("ctrl+shift+r", "client.tab.rename")
rex.bind("ctrl+shift+left", "pane.resize", { direction = "left", amount = 12 })
rex.bind("ctrl+shift+down", "pane.resize", { direction = "down", amount = 5 })
rex.bind("ctrl+shift+up", "pane.resize", { direction = "up", amount = 5 })
rex.bind("ctrl+shift+right", "pane.resize", { direction = "right", amount = 12 })
rex.bind("cmd+p", "pane.send_key", { key = "ctrl+p" })

-- Agent chats: live Claude / Codex panes in every session, their PRs and rv
-- reviews, and recently closed chats to resume. See ~/code/dotfilez/rex/agents.py.
local AGENTS_PICKER = os.getenv("HOME") .. "/code/dotfilez/rex/agents.py"
local AGENTS_LABEL = "agent-picker"

-- Floating layers in the session that hold an agent picker, as { layer_id, window_id }.
-- layer_id -> the pane each open picker was opened from.
local picker_origins = {}

local function open_agent_pickers()
  local view = rex.session.view{} or {}
  local found = {}

  for _, window in ipairs(view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        local is_picker = layer.kind ~= "tiled" and block.label == AGENTS_LABEL
        if is_picker then
          table.insert(found, { layer_id = layer.layer_id, window_id = window.window_id })
        end
      end
    end
  end

  return found
end

-- The window the key was pressed in. Without it, new_layer uses the server's
-- active window, which can be a different tab than the one on screen.
local function action_window(ctx)
  if not ctx.block_id then
    return nil
  end

  local described = rex.session.describe_block{ block_id = ctx.block_id }
  local block = described and described.block or {}

  return block.window_id
end

rex.action{
  name = "agents",
  title = "Agent Chats…",
  description = "Find a live agent chat, open its PR, or resume a closed one.",
  keywords = "claude codex history resume pr rv review",
  run = function(ctx, args)
    local window_id = action_window(ctx)

    -- One picker at a time: pressing the key again closes it, and pressing it
    -- in another tab moves it there.
    local closed_here = nil
    for _, picker in ipairs(open_agent_pickers()) do
      if picker.window_id == window_id then
        closed_here = picker
      end
      rex.session.close_layer{ layer_id = picker.layer_id }
    end

    -- Closing a layer lets Rex choose the next focused pane, so put focus back
    -- on the pane the picker was opened from.
    if closed_here then
      local origin = picker_origins[closed_here.layer_id]
      picker_origins[closed_here.layer_id] = nil
      if origin then
        rex.session.focus_block{ block_id = origin }
      end
      return
    end

    local origin = ctx.block_id or ""
    local layer, err = rex.session.new_layer{
      window_id = window_id,
      bounds = { 0.03, 0.03, 0.94, 0.94 },
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = AGENTS_LABEL,
        options = {
          command = { "python3", AGENTS_PICKER, "--pick", "--client", ctx.client_id or "", "--origin", origin },
        },
      },
    }
    if err ~= nil then
      error(err, 0)
    end

    picker_origins[layer.layer_id] = ctx.block_id
  end,
}

rex.bind("shift+cmd+a", "agents")

-- New tab running `yolo` (zsh function in ~/.config/zsh/aliases.zsh), in the
-- directory of the pane the key was pressed in. yolo is a shell function, so
-- it runs through an interactive zsh, which reads the file that defines it.
-- The Rex server's PATH does not include rex.
local REX_CLI = os.getenv("HOME") .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"

rex.action{
  name = "claude_tab",
  title = "New Claude Code Tab",
  description = "Open a tab running yolo in the focused pane's directory.",
  keywords = "claude yolo agent",
  run = function(ctx, args)
    local process = ctx.block_id and rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    local foreground = process and process.foreground or {}

    local window, err = rex.session.new_window{
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = "claude",
        options = {
          shell = "none",
          command = { "/bin/zsh", "-lic", "yolo" },
          cwd = foreground.cwd or "",
        },
      },
    }
    if err ~= nil then
      error(err, 0)
    end

    -- new_window makes the tab active on the server; the app keeps showing the
    -- tab it was on until it is told to select the new one.
    local can_select = ctx.client_id ~= nil and ctx.session_id ~= nil
    if not can_select then
      rex.log("warn", "claude_tab: no client or session in ctx, tab opened without focus")
      return
    end

    -- The app ignores a session.select queued from here for a window it has not
    -- heard about yet. A detached CLI call lets run() return right away and
    -- reaches the app about 30ms later, after the window has.
    local select_argv = {
      REX_CLI,
      "-C",
      ctx.client_id,
      "do",
      "session.select",
      "session_id=" .. ctx.session_id,
      "window_id=" .. window.window_id,
    }
    local handle, start_err = rex.exec.start(select_argv, { detach = true })
    if not handle then
      rex.log("warn", "claude_tab: could not ask the app to show the new tab: " .. tostring(start_err))
    end
  end,
}

rex.bind("ctrl+shift+t", "claude_tab")

rex.bind("shift+cmd+r", "session.rename")
rex.bind("shift+cmd+m", "session.next")

-- Pane navigation, ported from kitty's pass_keys.py:
--   ctrl+h/l  goes to nvim or fzf when one runs in the pane (nvim calls
--             `rex focus` at its edge, see nvim/lua/core/rex_navigator.lua),
--             and moves between Rex panes otherwise.
--   ctrl+j/k  moves between Rex panes when there is one above or below, and
--             otherwise sends the down / up arrow to the program.
-- Overlays Rex knows by label (the agent picker, copy mode, hints) get all four keys:
-- fzf uses ctrl+h for history and ctrl+j/k to move, and Rex reports the
-- picker's process as Python and copy mode's as login, not fzf or nvim.
local NAV_PROGRAMS = { "nvim", "vim", "fzf" }

local PASSTHROUGH_LABELS = { "agent-picker", "(copy-mode)", "hints" }

local function is_passthrough(block_id)
  local described = rex.session.describe_block{ block_id = block_id }
  local label = described and described.block and described.block.label or ""

  for _, prefix in ipairs(PASSTHROUGH_LABELS) do
    if label:sub(1, #prefix) == prefix then
      return true
    end
  end

  return false
end

local function runs_nav_program(block_id)
  local process = rex.block.call("com.superlogical.terminal", "process", { block_id = block_id })
  local foreground = process and process.foreground or {}
  local name = (foreground.name or ""):lower()
  local argv0 = ((foreground.argv0 or ""):match("[^/]+$") or ""):lower()

  for _, program in ipairs(NAV_PROGRAMS) do
    if name == program or argv0 == program then
      return true
    end
  end

  return false
end

-- Moves focus from the pane the key was pressed in. Returns false when there
-- was no pane in that direction: focus_direction succeeds without changing
-- anything, so the session revision stays the same.
local function focus_from(block_id, direction)
  rex.session.focus_block{ block_id = block_id }

  local before = (rex.session.view{} or {}).revision
  local moved = rex.session.focus_direction{ direction = direction }

  return moved ~= nil and moved.revision ~= before
end

rex.action{
  name = "navigate",
  title = "Navigate Pane or Editor",
  args = { direction = "string", key = "string", fallback = "string?" },
  run = function(ctx, args)
    if not ctx.block_id then
      rex.client.queue("pane.focus", { direction = args.direction })
      return
    end

    if is_passthrough(ctx.block_id) then
      rex.client.queue("pane.send_key", { key = args.key })
      return
    end

    local is_vertical = args.direction == "up" or args.direction == "down"

    if is_vertical then
      local moved = focus_from(ctx.block_id, args.direction)
      if not moved and args.fallback then
        rex.client.queue("pane.send_key", { key = args.fallback })
      end
      return
    end

    if runs_nav_program(ctx.block_id) then
      rex.client.queue("pane.send_key", { key = args.key })
      return
    end

    focus_from(ctx.block_id, args.direction)
  end,
}

rex.bind("ctrl+h", "navigate", { direction = "left", key = "ctrl+h" })
rex.bind("ctrl+j", "navigate", { direction = "down", key = "ctrl+j", fallback = "down" })
rex.bind("ctrl+k", "navigate", { direction = "up", key = "ctrl+k", fallback = "up" })
rex.bind("ctrl+l", "navigate", { direction = "right", key = "ctrl+l" })

-- Copy mode, kitty's ctrl+1: the pane's scrollback with colors in an nvim
-- overlay with Kanagawa. Any yank copies and returns, [[ ]] jump between
-- prompts, q closes. Viewer setup: ~/code/dotfilez/rex/copy-mode-init.lua.
-- Plugin: copy-mode*.lua in this directory, from CJNE/rex-copy-mode with
-- `init` and `snapshot` options added.
-- The Rex server's PATH has neither nvim nor rex, so give both explicitly.
-- Claude Code draws on the alternate screen, so Rex has no scrollback for it.
-- For a Claude pane, show its whole transcript instead (prompts start with ❯,
-- so [[ ]] jump between them). Anything else falls back to the pane capture.
local CLAUDE_TRANSCRIPT = os.getenv("HOME") .. "/code/dotfilez/rex/claude_transcript.py"

local function claude_snapshot(ctx)
  local process = rex.block.call("com.superlogical.terminal", "process", {
    session_id = ctx.session_id,
    block_id = ctx.block_id,
  })
  local foreground = process and process.foreground or {}
  local argv0 = (foreground.argv0 or ""):match("[^/]+$") or ""
  if argv0 ~= "claude" or not foreground.pid then
    return nil
  end

  local result, err = rex.exec({ "/usr/bin/python3", CLAUDE_TRANSCRIPT, tostring(foreground.pid) }, { timeout = 10 })
  if not result then
    rex.log("warn", "copy-mode: claude transcript did not run: " .. tostring(err))
    return nil
  end

  return result.ok and result.stdout or nil
end

require("copy-mode").setup({
  key = false,
  copy_key = false,
  snapshot = claude_snapshot,
  init = os.getenv("HOME") .. "/code/dotfilez/rex/copy-mode-init.lua",
  nvim = "/opt/homebrew/bin/nvim",
  rex = os.getenv("HOME") .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
})

-- ctrl+1 toggles: pressed inside copy mode it closes it with Esc (keeping
-- copy mode's cleanup and focus restore) instead of opening one on top.
rex.action{
  name = "copy_mode_toggle",
  title = "Toggle Copy Mode",
  category = "Pane",
  run = function(ctx, args)
    local described = ctx.block_id and rex.session.describe_block{ block_id = ctx.block_id }
    local label = described and described.block and described.block.label or ""
    local in_copy_mode = label:sub(1, #"(copy-mode)") == "(copy-mode)"

    -- Type Esc into that pane itself; the app's focused pane may be elsewhere.
    if in_copy_mode then
      local _, err = rex.block.call("com.superlogical.terminal", "write", {
        session_id = ctx.session_id,
        block_id = ctx.block_id,
        args = { data = "\27" },
      })
      if err ~= nil then
        error(err, 0)
      end
      return
    end

    local result, err = rex.invoke("copy_mode", {})
    if err ~= nil then
      error(err, 0)
    end

    return result
  end,
}

rex.bind("ctrl+1", "copy_mode_toggle")

-- Hints, kitty's `kitten hints`: label every match of a kind on the pane's
-- screen, type a label to open or copy it, Esc cancels. The overlay sits
-- exactly over the pane. See ~/code/dotfilez/rex/hints.py.
local HINTS_SCRIPT = os.getenv("HOME") .. "/code/dotfilez/rex/hints.py"
local HINTS_LABEL = "hints"
local overlay_geometry = dofile(os.getenv("HOME") .. "/code/dotfilez/rex/copy-mode-common.lua")

rex.action{
  name = "hints",
  title = "Hints…",
  description = "Label URLs, paths, hashes, lines, branches or resume commands on screen to open or copy.",
  keywords = "kitten hints url path hash open copy select",
  args = { kind = "string" },
  run = function(ctx, args)
    if not ctx.block_id then
      error("hints needs a focused pane", 0)
    end

    local described = rex.session.describe_block{ block_id = ctx.block_id }
    local block = described and described.block or {}

    -- Pressed inside a hints overlay: close it instead of stacking another.
    if block.label == HINTS_LABEL then
      rex.block.call("com.superlogical.terminal", "write", {
        session_id = ctx.session_id,
        block_id = ctx.block_id,
        args = { data = "\27" },
      })
      return
    end

    local view = rex.session.view{} or {}
    local bounds = overlay_geometry.pane_bounds(view, block.window_id, ctx.block_id)

    local _, err = rex.session.new_layer{
      window_id = block.window_id,
      bounds = bounds,
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        label = HINTS_LABEL,
        options = {
          command = {
            "/usr/bin/python3", HINTS_SCRIPT,
            "--session", ctx.session_id, "--block", ctx.block_id, "--kind", args.kind,
          },
        },
      },
    }
    if err ~= nil then
      error(err, 0)
    end
  end,
}

-- kitty_mod = ctrl+shift, as in kitty.conf
rex.bind("ctrl+shift+e", "hints", { kind = "url" })
rex.bind("ctrl+shift+y", "hints", { kind = "hyperlink" })
rex.bind("ctrl+shift+f", "hints", { kind = "path" })
rex.bind("ctrl+shift+h", "hints", { kind = "hash" })
rex.bind("ctrl+shift+l", "hints", { kind = "line" })
rex.bind("ctrl+shift+b", "hints", { kind = "branch" })
rex.bind("ctrl+shift+c", "hints", { kind = "resume" })

-- Fork the Claude chat in the focused pane into a split beside it, kitty's
-- cmd+shift+f (kitty/kittens/fork_session.py): `claude --resume <id>
-- --fork-session` with the original launch flags, so the fork keeps the
-- conversation and permission mode but writes a new session. It runs in an
-- interactive zsh for the usual PATH, and the split stays a shell afterwards.
local FORK_FLAGS_WITH_VALUE = { ["--resume"] = true, ["-r"] = true, ["--session-id"] = true }
local FORK_FLAGS_STANDALONE = { ["--fork-session"] = true, ["--continue"] = true, ["-c"] = true }

local function shell_quote(word)
  return "'" .. word:gsub("'", "'\\''") .. "'"
end

-- Claude's launch command without the flags that pick a session.
local function claude_launch_args(pid)
  local result = rex.exec({ "ps", "-o", "args=", "-p", tostring(pid) }, { timeout = 5 })
  if not (result and result.ok) then
    return nil
  end

  local words = {}
  for word in result.stdout:gmatch("%S+") do
    table.insert(words, word)
  end

  local args = {}
  local skip_next = false
  for index, word in ipairs(words) do
    local flag = word:match("^([^=]+)=") or word
    local takes_value = FORK_FLAGS_WITH_VALUE[word] and words[index + 1] and words[index + 1]:sub(1, 1) ~= "-"

    if skip_next then
      skip_next = false
    elseif index == 1 or FORK_FLAGS_STANDALONE[word] or FORK_FLAGS_WITH_VALUE[flag] then
      skip_next = takes_value or false
    else
      table.insert(args, word)
    end
  end

  return args
end

local function claude_session_file(pid)
  local file = io.open(os.getenv("HOME") .. "/.claude/sessions/" .. pid .. ".json", "r")
  if not file then
    return nil
  end

  local data = file:read("*a")
  file:close()

  return rex.json.decode(data)
end

rex.action{
  name = "fork_claude",
  title = "Fork Claude Chat",
  description = "Open a split beside this pane running a fork of its Claude chat.",
  keywords = "claude fork session split resume",
  run = function(ctx, args)
    if not ctx.block_id then
      error("fork: no focused pane", 0)
    end

    local process = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    local foreground = process and process.foreground or {}
    local argv0 = (foreground.argv0 or ""):match("[^/]+$") or ""
    if argv0 ~= "claude" or not foreground.pid then
      error("fork: no Claude chat in this pane", 0)
    end

    local session = claude_session_file(foreground.pid) or {}
    if not session.sessionId then
      error("fork: no session file for Claude pid " .. foreground.pid, 0)
    end

    local launch_args = claude_launch_args(foreground.pid)
    if not launch_args then
      error("fork: could not read Claude's command line (pid " .. foreground.pid .. ")", 0)
    end

    local words = { "command", "claude" }
    for _, word in ipairs(launch_args) do
      table.insert(words, shell_quote(word))
    end
    table.insert(words, "--resume")
    table.insert(words, shell_quote(session.sessionId))
    table.insert(words, "--fork-session")

    -- `command` skips a zsh alias for claude that would repeat the flags.
    local claude = table.concat(words, " ")

    local _, err = rex.session.new_split{
      anchor_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = rex.layout.block{
        flavor = "com.superlogical.terminal.shell",
        options = {
          cwd = session.cwd or foreground.cwd,
          command = { "/bin/zsh", "-ic", claude .. "; exec /bin/zsh -l" },
        },
      },
    }
    if err ~= nil then
      error(err, 0)
    end
  end,
}

rex.bind("shift+cmd+f", "fork_claude")
