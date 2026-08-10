-- Hammerspoon config
-- hyper = ctrl+alt+cmd, the main modifier for all bindings below

local hyper = { "ctrl", "alt", "cmd" }

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

-- Each entry maps a key to a unit rect: { x, y, w, h } as screen fractions.
local layouts = {
  left  = { key = "left",  rect = { 0.0, 0.0, 0.5, 1.0 } },
  right = { key = "right", rect = { 0.5, 0.0, 0.5, 1.0 } },
  up    = { key = "up",    rect = { 0.0, 0.0, 1.0, 1.0 } }, -- maximize
  down  = { key = "down",  rect = { 0.25, 0.25, 0.5, 0.5 } }, -- center
}

local function moveFocusedWindow(rect)
  local win = hs.window.focusedWindow()
  if not win then
    hs.alert.show("No focused window")
    return
  end

  win:moveToUnit(hs.geometry.rect(rect))
end

for _, layout in pairs(layouts) do
  hs.hotkey.bind(hyper, layout.key, function()
    moveFocusedWindow(layout.rect)
  end)
end

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

hs.alert.show("Hammerspoon config loaded")
