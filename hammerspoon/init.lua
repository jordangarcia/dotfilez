-- Hammerspoon config
-- hyper = ctrl+alt+cmd, the main modifier for all bindings below

local hyper = { "ctrl", "alt", "cmd" }

local appLauncher = require("app-launcher")
local notifications = require("notifications")

-- Raycast still owns the alt+<letter> app aliases and alt+shift+delete.
-- Flip this to true only after turning those aliases off in Raycast,
-- otherwise both handlers fire on the same chord.
local enableRaycastPort = false

-- ── Setup: CLI + alerts ────────────────────────────────────────────

-- Installs the `hs` command line tool into ~/.local/bin.
-- /usr/local/bin is root-owned on this machine, so the default prefix fails silently.
-- Safe to call on every load; it is a no-op when already installed.
hs.ipc.cliInstall(os.getenv("HOME") .. "/.local")

hs.alert.defaultStyle.radius = 8
hs.alert.defaultStyle.textSize = 20

-- ── Config reload ──────────────────────────────────────────────────

-- Watch the config directory and reload on any .lua change,
-- so edits apply without touching the console.
-- pathToAbsolute resolves the ~/.hammerspoon symlink; FSEvents does not
-- follow symlinks, so watching the link path would miss edits in dotfilez.
local configDir = hs.fs.pathToAbsolute(hs.configdir)

local configWatcher = hs.pathwatcher.new(configDir, function(files)
  local hasLuaChange = hs.fnutils.some(files, function(file)
    return file:sub(-4) == ".lua"
  end)

  if hasLuaChange then
    hs.reload()
  end
end)
configWatcher:start()

hs.hotkey.bind(hyper, "r", function()
  hs.reload()
end)

-- ── Window management ──────────────────────────────────────────────

-- Instant snapping; animation makes rapid re-tiling feel laggy.
hs.window.animationDuration = 0

-- alt bindings place the focused window on the screen under the mouse.
local function moveFocusedWindowToMouseScreen(rect)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window")
    return
  end

  local mouseScreen = hs.mouse.getCurrentScreen()
  if not mouseScreen then
    return
  end

  win:moveToScreen(mouseScreen)
  win:moveToUnit(hs.geometry.rect(rect))
end

local mouseScreenLayouts = {
  f = { 0.0, 0.0, 1.0, 1.0 }, -- fill screen
  q = { 0.0, 0.0, 0.5, 1.0 }, -- left half
  w = { 0.5, 0.0, 0.5, 1.0 }, -- right half
}

for key, rect in pairs(mouseScreenLayouts) do
  hs.hotkey.bind({ "alt" }, key, function()
    moveFocusedWindowToMouseScreen(rect)
  end)
end

-- Move the focused window to the next screen.
hs.hotkey.bind(hyper, "n", function()
  local win = hs.window.focusedWindow()
  if not win then
    return
  end

  win:moveToScreen(win:screen():next())
end)

-- ── App launcher hotkeys ───────────────────────────────────────────

-- hyper + key focuses the app, or starts it when it is not open.
local appHotkeys = {
  t = "Ghostty",
  b = "Google Chrome",
}

for key, appName in pairs(appHotkeys) do
  hs.hotkey.bind(hyper, key, function()
    hs.application.launchOrFocus(appName)
  end)
end

-- ── Update-restart blocker ─────────────────────────────────────────

-- macOS only auto-restarts for updates when the machine looks idle.
-- caffeinate -dis holds display/system/disk assertions, so the machine
-- never looks idle and the restart stays delayed while the toggle is on.
local restartBlocker = {
  task = nil,
  menu = hs.menubar.new(),
}

local function updateBlockerMenu()
  local isOn = restartBlocker.task ~= nil

  restartBlocker.menu:setTitle(isOn and "☕" or "💤")
  restartBlocker.menu:setTooltip(isOn and "Update restart delayed (caffeinate on)" or "Update restart allowed")
end

-- If something kills the caffeinate while the toggle is on, start a new
-- one right away. Only the toggle turns it off for real.
local function startBlockerTask()
  restartBlocker.task = hs.task.new("/usr/bin/caffeinate", function()
    local wantedAlive = restartBlocker.task ~= nil
    if wantedAlive then
      hs.alert.show("caffeinate died — restarting it")
      startBlockerTask()
    end
  end, { "-dis" })

  restartBlocker.task:start()
end

local function toggleRestartBlocker()
  if restartBlocker.task then
    local task = restartBlocker.task
    restartBlocker.task = nil -- clear first so the exit callback does not respawn
    task:terminate()
    hs.alert.show("Update restart allowed")
  else
    startBlockerTask()
    hs.alert.show("Update restart delayed")
  end

  updateBlockerMenu()
end

restartBlocker.menu:setClickCallback(toggleRestartBlocker)
updateBlockerMenu()

-- Global so `hs -c "toggleUpdateBlocker()"` works from the shell.
toggleUpdateBlocker = toggleRestartBlocker

-- The caffeinate child dies with Hammerspoon, so a config reload or quit
-- releases the assertions. The menu state resets to off on reload.

-- ── Raycast port: app aliases + dismiss notifications ───────────

if enableRaycastPort then
  appLauncher.start()
  notifications.bindDismissAll({ "alt", "shift" }, "delete")
end

hs.alert.show("Hammerspoon config loaded")
