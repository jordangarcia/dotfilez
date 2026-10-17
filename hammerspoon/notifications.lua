-- Dismiss every visible Notification Center banner. Port of
-- raycast-scripts/close-notifications.applescript.
--
-- Requires Hammerspoon to hold Accessibility permission
-- (System Settings → Privacy & Security → Accessibility).

local M = {}

-- Dismissal is exposed as an AX *action* on the notification element, not
-- as a close button in the tree -- the visible ✕ exists only while the
-- pointer hovers. Match on the action's description, which Notification
-- Center localizes, so this list is English-only by design.
local closeActionLabels = {
  ["Close"] = true,
  ["Clear All"] = true,
}

-- Each close rebuilds the stack, so the walk closes one notification and
-- returns; the caller re-scans. The cap stops a notification that refuses
-- to close from spinning forever.
local maxPasses = 30

-- Notification Center needs a moment to collapse the stack before the next
-- scan. Without it the same element comes back and the action no-ops.
local settleDelay = 50 * 1000

local function performCloseAction(element)
  local names = element:actionNames() or {}

  for _, name in ipairs(names) do
    local label = element:actionDescription(name)

    if label and closeActionLabels[label] then
      element:performAction(name)
      return true
    end
  end

  return false
end

-- Depth-first, deepest child first: a notification's own close action sits
-- above the group it belongs to, and closing the group first invalidates
-- everything under it.
local function closeFirstNotification(element)
  local children = element:attributeValue("AXChildren") or {}

  for _, child in ipairs(children) do
    if closeFirstNotification(child) then
      return true
    end
  end

  return performCloseAction(element)
end

-- Banners and the notification list both live in a window titled
-- "Notification Center". Fall back to every window when no title matches,
-- since it has changed between macOS releases.
local function notificationRoots(ax)
  local windows = ax:attributeValue("AXWindows") or {}

  local named = hs.fnutils.filter(windows, function(window)
    return window:attributeValue("AXTitle") == "Notification Center"
  end)

  if #named > 0 then
    return named
  end

  return windows
end

local function closeOne(ax)
  local roots = notificationRoots(ax)

  return hs.fnutils.some(roots, function(root)
    local ok, closed = pcall(closeFirstNotification, root)

    -- A close mid-walk can invalidate an element and throw; treat that as
    -- "nothing closed here" and let the next pass re-scan.
    return ok and closed
  end)
end

-- Returns the number of banners actually dismissed.
function M.dismissAll()
  local app = hs.application.get("com.apple.notificationcenterui")
  if not app then
    return 0
  end

  local ax = hs.axuielement.applicationElement(app)
  if not ax then
    return 0
  end

  local dismissed = 0

  for _ = 1, maxPasses do
    if not closeOne(ax) then
      break
    end

    dismissed = dismissed + 1
    hs.timer.usleep(settleDelay)
  end

  return dismissed
end

-- Stays quiet on success -- the banners visibly disappear. Alerts only when
-- nothing moved, which usually means the AX permission was revoked.
function M.bindDismissAll(mods, key)
  return hs.hotkey.bind(mods, key, function()
    local dismissed = M.dismissAll()

    if dismissed == 0 then
      hs.alert.show("No notifications to dismiss")
    end
  end)
end

return M
