-- ~/.config/hammerspoon/Spoons/PathCopy.spoon/init.lua

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "FinderPathCopy"
obj.version = "0.1"
obj.author = "Jordan Garcia"
-- obj.homepage = "https://github.com/yourusername/PathCopy.spoon"
-- obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Default settings
obj.default_hotkey = { { "cmd", "shift" }, "C" }

function obj:init()
	return self
end

function obj:bindHotkeys(mapping)
	local spec = {
		copyPath = hs.fnutils.partial(self.copyCurrentPath, self),
	}
	hs.spoons.bindHotkeysToSpec(spec, mapping)
end

function obj:copyCurrentPath()
	local finder = hs.appfinder.appFromName("Finder")
	if finder == nil then
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
		-- Copy to clipboard
		hs.pasteboard.setContents(result)
		-- Optional: Show notification
		hs.notify.new({ title = "PathCopy", informativeText = "Path copied to clipboard" }):send()
	end
end

return obj
