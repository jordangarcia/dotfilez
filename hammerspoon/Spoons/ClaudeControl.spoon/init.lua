--- === ClaudeControl ===
---
--- Control Claude window and focus
---
--- Download: [https://github.com/YOUR_USERNAME/YOUR_REPO/raw/master/Spoons/ClaudeControl.spoon.zip](https://github.com/YOUR_USERNAME/YOUR_REPO/raw/master/Spoons/ClaudeControl.spoon.zip)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ClaudeControl"
obj.version = "1.0"
obj.author = "YOUR_NAME"
obj.homepage = "https://github.com/YOUR_USERNAME/YOUR_REPO"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:init()
	self.claudeApp = nil
	self.claudeWindow = nil
end

--- ClaudeControl:focusOrOpen()
--- Method
--- Focuses the Claude window if it exists, or opens Claude if it doesn't.
--- Also focuses the "Reply to Claude" input box after the window is focused.
function obj:focusOrOpen()
	-- Try to find Claude app
	self.claudeApp = hs.application.find("Claude")

	if self.claudeApp then
		-- App exists, focus it
		self.claudeApp:activate()
		self.claudeWindow = self.claudeApp:focusedWindow()

		if self.claudeWindow then
			-- Focus the "Reply to Claude" input box
			hs.timer.doAfter(0.1, function()
				-- First try clicking the input area
				local windowFrame = self.claudeWindow:frame()
				local clickX = 100
				local clickY = windowFrame.y + windowFrame.h - 65 -- Adjust this value if needed

				hs.alert(hs.inspect(tbl), 30)

				hs.inspect(tbl)

				-- Move mouse and click
				hs.mouse.absolutePosition({ x = clickX, y = clickY })
				hs.eventtap.leftClick({ x = clickX, y = clickY })

				-- As a fallback, also send cmd+/ which is the default shortcut
				hs.timer.doAfter(0.05, function()
					hs.eventtap.keyStroke({ "cmd" }, "/")
				end)
			end)
		end
	else
		-- App doesn't exist, open it
		hs.application.open("Claude")

		-- Wait for app to open and then focus input
		hs.timer.doAfter(1, function()
			self.claudeApp = hs.application.find("Claude")
			if self.claudeApp then
				self.claudeWindow = self.claudeApp:focusedWindow()
				-- Focus input using the same method as above
				hs.timer.doAfter(0.1, function()
					local windowFrame = self.claudeWindow:frame()
					local clickX = windowFrame.x + windowFrame.w / 2
					local clickY = windowFrame.y + windowFrame.h - 50

					hs.mouse.absolutePosition({ x = clickX, y = clickY })
					hs.eventtap.leftClick({ x = clickX, y = clickY })

					hs.timer.doAfter(0.05, function()
						hs.eventtap.keyStroke({ "cmd" }, "/")
					end)
				end)
			end
		end)
	end
end

--- ClaudeControl:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for ClaudeControl
---
--- Parameters:
---  * mapping - A table containing hotkey details for the following items:
---   * focus - Focus or open Claude
function obj:bindHotkeys(mapping)
	local spec = {
		focus = hs.fnutils.partial(self.focusOrOpen, self),
	}
	hs.spoons.bindHotkeysToSpec(spec, mapping)
end

return obj
