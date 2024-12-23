-- annotate hs as globalv ariable
-- setup defaults
local alertStyle = {
	strokeWidth = 2,
	padding = 10,
	radius = 5,
	textFont = "Victor Mono SemiBold",
	textSize = 14,
	-- atScreenEdge = 1,
}

local notify = function(msg, duration)
	duration = duration or 1
	local screen = hs.screen.mainScreen()
	local frame = screen:fullFrame()
	hs.alert.show(msg, alertStyle, screen, duration)
	-- hs.notify.new({ title = "Battery Watcher", informativeText = msg }):send()
end

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "W", function()
	hs.alert.show("Hello World!")
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "C", function()
	spoon.AClock:toggleShow()
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "R", function()
	hs.reload()
end)

hs.hotkey.bind({ "cmd", "alt", "ctrl" }, "H", function()
	local finder = hs.appfinder.appFromName("Finder")
	if finder == nil or not finder:isFrontmost() then
		return
	end

	-- Get the Finder window
	local window = finder:focusedWindow()
	if window == nil then
		return
	end

	-- AppleScript to get the current directory path
	local script = [[
        tell application "Finder"
            if exists window 1 then
                get POSIX path of (target of window 1 as alias)
            end if
        end tell
    ]]

	local ok, result = hs.osascript.applescript(script)

	if ok and result then
		hs.pasteboard.setContents(result)
		-- Get screen frame
		notify("Copied to clipboard: " .. result)
	end
end)

local main_modal = hs.hotkey.modal.new("alt", "space")

function main_modal:entered()
	notify("r - Reload config")
	notify("c - show console")
end

main_modal:bind("", "r", function()
	hs.reload()
	main_modal:exit()
end)

main_modal:bind("", "c", function()
	hs.openConsole()
	main_modal:exit()
end)

function main_modal:exited()
	hs.alert.closeAll()
end

local modal = hs.hotkey.modal.new("alt", "h")

function modal:entered()
	hs.alert.show("a - Connect AirPods", {
		strokeWidth = 2,
		fadeOutDuration = 0.3,
		padding = 10,
		radius = 5,
		textFont = "Victor Mono SemiBold",
		textSize = 12,
	})
end

function modal:exited()
	hs.alert.closeAll()
end

modal:bind("", "a", function()
	output, status, termType, rc = hs.execute("/Users/jordan/code/dotfilez/bin/airpods c", true)
	-- -- output, status, termType, rc = hs.execute("open ~/", true)
	modal:exit()
	notify(output, 2)
	notify(rc, 2)
end)

modal:bind("", "escape", function()
	modal:exit()
end)

hs.hotkey.bind({ "shift", "alt" }, "W", function()
	-- Get the currently focused window
	local focusedWindow = hs.window.focusedWindow()
	if not focusedWindow then
		return
	end

	-- Get the application of the focused window
	local focusedApp = focusedWindow:application()
	if not focusedApp then
		return
	end

	-- Get all windows of the current application
	local allWindows = focusedApp:allWindows()

	-- Close all windows except the focused one
	for _, window in ipairs(allWindows) do
		if window ~= focusedWindow then
			window:close()
		end
	end

	-- Optional: Show notification
	hs.notify
		.new({
			title = "Windows Closed",
			informativeText = "Closed other windows of " .. focusedApp:name(),
		})
		:send()
end)

notify("Config loaded")
