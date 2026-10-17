-- Raycast-style app hotkeys: a modifier plus a letter focuses an app,
-- launching it when it is not already running.
--
-- Targets are bundle IDs rather than names. Several of these are Chrome
-- PWAs installed under a generic name, so there are two "Claude.app" and
-- two "Linear.app" on disk and name lookup picks whichever it finds first.

local M = {}

local alt = { "alt" }
local altShift = { "alt", "shift" }

local apps = {
  { mods = alt,      key = "b", name = "Bear",           bundleID = "net.shinyfrog.bear" },
  { mods = alt,      key = "a", name = "Claude (web)",   bundleID = "com.google.Chrome.app.fmpnliohjhemenmnlpbfagaolkdacoja" },
  { mods = altShift, key = "a", name = "Claude desktop", bundleID = "com.anthropic.claudefordesktop" },
  { mods = alt,      key = "d", name = "Devin",          bundleID = "com.exafunction.windsurf" },
  { mods = alt,      key = "g", name = "Figma",          bundleID = "com.figma.Desktop" },
  { mods = alt,      key = "o", name = "Finder",         bundleID = "com.apple.finder" },
  { mods = alt,      key = "j", name = "Google Chrome",  bundleID = "com.google.Chrome" },
  { mods = alt,      key = ";", name = "Linear",         bundleID = "com.google.Chrome.app.bgdbmehlmdmddlgneophbcddadgknlpm" },
  { mods = alt,      key = "i", name = "Messages",       bundleID = "com.apple.MobileSMS" },
  { mods = alt,      key = "m", name = "Music",          bundleID = "com.apple.Music" },
  { mods = alt,      key = "n", name = "Notion",         bundleID = "notion.id" },
  { mods = alt,      key = "c", name = "Obsidian",       bundleID = "md.obsidian" },
  { mods = alt,      key = "p", name = "Preview",        bundleID = "com.apple.Preview" },
  { mods = alt,      key = "l", name = "Slack",          bundleID = "com.tinyspeck.slackmacgap" },
  { mods = alt,      key = "u", name = "Spotify",        bundleID = "com.spotify.client" },
  { mods = alt,      key = ",", name = "System Settings", bundleID = "com.apple.systempreferences" },
  { mods = alt,      key = "z", name = "Zoom",           bundleID = "us.zoom.xos" },
  { mods = alt,      key = "k", name = "kitty",          bundleID = "net.kovidgoyal.kitty" },
}

local function focusApp(app)
  local launched = hs.application.launchOrFocusByBundleID(app.bundleID)
  if not launched then
    hs.alert.show("Could not launch " .. app.name)
  end
end

local hotkeys = {}

-- Binding alt+<letter> swallows the option-character it would otherwise
-- type (alt+k stops producing ˚, and so on) everywhere in the system.
function M.start()
  if #hotkeys > 0 then
    return
  end

  hotkeys = hs.fnutils.map(apps, function(app)
    return hs.hotkey.bind(app.mods, app.key, function()
      focusApp(app)
    end)
  end)
end

function M.stop()
  hs.fnutils.each(hotkeys, function(hotkey)
    hotkey:delete()
  end)

  hotkeys = {}
end

return M
