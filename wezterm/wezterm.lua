---@diagnostic disable: unused-local
-- Pull in the wezterm API
local wezterm = require("wezterm")
local balance = require("plugins.balance")
local palette = require("colors.palette")
local k = require("joshwez.utils.keys")
local act = wezterm.action
local mux = wezterm.mux
local mods = require("mods")
local hyper = "CTRL|SHIFT"

local function padString(str, length)
	local padding = length - string.len(str)
	local leftPadding = math.floor(padding / 2)
	local rightPadding = padding - leftPadding

	local paddedString = string.rep(" ", leftPadding) .. str .. string.rep(" ", rightPadding)

	return paddedString
end

-- tab titling
local function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local title = tab_title(tab)
	local index = tab.tab_index + 1

	if tab.is_active then
		return {
			{ Background = { Color = palette.carpYellow } },
			{ Foreground = { Color = palette.sumiInk3 } },
			{ Text = padString(index .. " " .. title, 16) },
		}
	end

	return {
		{ Text = padString(index .. " " .. title, 16) },
	}
end)

local function isViProcess(pane)
	-- get_foreground_process_name On Linux, macOS and Windows,
	-- the process can be queried to determine this path. Other operating systems
	-- (notably, FreeBSD and other unix systems) are not currently supported
	return pane:get_foreground_process_name():find("n?vim") ~= nil
	-- return pane:get_title():find("n?vim") ~= nil
end

local function conditionalActivatePane(window, pane, pane_direction, vim_direction)
	if isViProcess(pane) then
		window:perform_action(
			-- This should match the keybinds you set in Neovim.
			act.SendKey({ key = vim_direction, mods = "CTRL" }),
			pane
		)
	else
		window:perform_action(act.ActivatePaneDirection(pane_direction), pane)
	end
end

-- open sidepane if only pane
wezterm.on("side-pane", function(window, pane)
	local tab = window:active_tab()
	local panes = tab:panes()
	if #panes == 1 then
		panes[1]:split({ size = 0.3 })
		return
	end

	local right_pane = tab:get_pane_direction("Right")

	if #panes == 2 and right_pane then
		right_pane:activate()
	end
end)

wezterm.on("close-even", function(window, pane)
	local winid = window:window_id()
	local res = balance.close_direction()(window, pane)
	local before = balance.sibling_counts(window, pane)

	window:perform_action(wezterm.action.CloseCurrentPane({ confirm = true }), pane)

	wezterm.time.call_after(0.02, function()
		local after = balance.sibling_counts(window, pane)
		local newX = before.x - after.x
		local newY = before.y - after.y

		local dir = newY > 0 and "y" or "x"
		balance.balance_panes(dir, pane:pane_id())(window, res.pane)
	end)
end)

wezterm.on("split-h-even", function(window, pane)
	pane:split({ direction = "Bottom" })
	balance.balance_panes("y")(window, pane)
end)

wezterm.on("split-v-even", function(window, pane)
	pane:split({ direction = "Right" })
	balance.balance_panes("x")(window, pane)
end)

wezterm.on("ActivatePaneDirection-right", function(window, pane)
	conditionalActivatePane(window, pane, "Right", "l")
end)
wezterm.on("ActivatePaneDirection-left", function(window, pane)
	conditionalActivatePane(window, pane, "Left", "h")
end)
wezterm.on("ActivatePaneDirection-up", function(window, pane)
	conditionalActivatePane(window, pane, "Up", "k")
end)
wezterm.on("ActivatePaneDirection-down", function(window, pane)
	conditionalActivatePane(window, pane, "Down", "j")
end)

-- This table will hold the configuration.
local config = {

	-- use_ime = false,
	-- start from scratch
	disable_default_key_bindings = true,
	-- tabs
	use_fancy_tab_bar = false,
	hide_tab_bar_if_only_one_tab = true,
	-- font = wezterm.font_with_fallback({ { family = "Hack Nerd Font", weight = "Bold" } }),
	font = wezterm.font_with_fallback({ { family = "JetBrainsMono Nerd Font", weight = "Bold" } }),
	font_size = 14,
	harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
	color_scheme = "jordan",
	adjust_window_size_when_changing_font_size = false,
	-- leader
	-- leader is only used for quickselect
	leader = { mods = hyper, key = "y" },
	-- window_padding = {
	-- 	left = 30,
	-- 	right = 30,
	-- 	top = 20,
	-- 	bottom = 0,
	-- },
	-- colors = require("colors.real-kanagawa").colors,
	colors = {
		audible_bell = "Disabled",

		selection_fg = "black",
		-- selection_bg = "#FFA066",
		selection_bg = "#fffacd",
		split = palette.waveAqua1,
		copy_mode_active_highlight_bg = { Color = "#000000" },
		copy_mode_active_highlight_fg = { AnsiColor = "Black" },
		copy_mode_inactive_highlight_bg = { Color = "#52ad70" },
		copy_mode_inactive_highlight_fg = { AnsiColor = "White" },

		quick_select_label_bg = { Color = palette.sakuraPink },
		quick_select_label_fg = { Color = "white" },
		quick_select_match_bg = { Color = palette.springBlue },
		quick_select_match_fg = { Color = "white" },

		tab_bar = {
			inactive_tab_edge = palette.sumiInk3,
			-- The color of the strip that goes along the top of the window
			-- (does not apply when fancy tab bar is in use)
			background = palette.sumiInk3,

			-- The active tab is the one that has focus in the window
			active_tab = {
				bg_color = palette.crystalBlue,
				fg_color = palette.sumiInk3,
			},

			-- Inactive tabs are the tabs that do not have focus
			inactive_tab = {
				bg_color = palette.sumiInk3,
				fg_color = palette.fujiGray,
			},

			-- You can configure some alternate styling when the mouse pointer
			-- moves over inactive tabs
			inactive_tab_hover = {
				bg_color = palette.sumiInk3,
				fg_color = palette.crystalBlue,
			},

			-- The new tab button that let you create new tabs
			new_tab = {
				bg_color = palette.sumiInk3,
				fg_color = palette.fujiGray,
			},

			-- You can configure some alternate styling when the mouse pointer
			-- moves over the new tab button
			new_tab_hover = {
				bg_color = palette.sumiInk3,
				fg_color = palette.crystalBlue,
			},
		},
	},
	-- inactive_pane_hsb = {
	-- 	saturation = 1.0,
	-- 	brightness = 0.6,
	-- },
	native_macos_fullscreen_mode = false,
	cell_width = 1,
	line_height = 1,
	window_decorations = "RESIZE",

	quick_select_alphabet = "123456789asdfqwerzxcvjklmiuopghtybn",
	keys = {
		-- basic stuff
		{ mods = "CMD", key = "h", action = act.HideApplication },
		{ mods = "CMD", key = "q", action = act.QuitApplication },
		{ mods = "CMD", key = "k", action = act.ActivateCommandPalette },
		{ mods = "CMD", key = "n", action = act.SpawnWindow },
		{ mods = "CMD", key = "t", action = act.SpawnTab("CurrentPaneDomain") },
		-- { mods = "CMD", key = "t", action = act.SpawnCommandInNewTab({ args = { "/bin/zsh -l" } }) },
		{ mods = "CMD", key = "=", action = act.IncreaseFontSize },
		{ mods = "CMD", key = "0", action = act.ResetFontSize },
		{ mods = "CMD", key = "-", action = act.DecreaseFontSize },
		-- { mods = "CMD", key = "w", action = act.CloseCurrentPane({ confirm = true }) },
		{ mods = "CMD", key = "w", action = act.EmitEvent("close-even") },
		{ mods = "CMD", key = "v", action = act.PasteFrom("Clipboard") },
		{ mods = "CMD", key = "c", action = act.CopyTo("Clipboard") },
		{ mods = hyper, key = "F9", action = act.ShowDebugOverlay },
		-- { mods = hyper, key = "l", action = act.ShowLauncher },
		-- { mods = hyper, key = "Enter", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		-- { mods = hyper, key = "'", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
		{ mods = hyper, key = "Enter", action = act.EmitEvent("split-v-even") },
		{ mods = hyper, key = '"', action = act.EmitEvent("split-h-even") },
		{ mods = hyper, key = "|", action = act.EmitEvent("side-pane") },
		{ mods = hyper, key = ";", action = act.RotatePanes("CounterClockwise") },
		{ mods = hyper, key = "z", action = act.TogglePaneZoomState },
		-- { mods = hyper, key = "t", action = act.EmitEvent("jordan-newtab") },
		{ mods = hyper, key = "F5", action = act.ReloadConfiguration },
		-- rename pane
		{
			key = "r",
			mods = hyper,
			action = act.PromptInputLine({
				description = "Enter new name for tab",
				action = wezterm.action_callback(function(window, pane, line)
					-- line will be `nil` if they hit escape without entering anything
					-- An empty string if they just hit enter
					-- Or the actual line of text they wrote
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		-- adjust pane sizes
		{ mods = hyper, key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ mods = hyper, key = "DownArrow", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ mods = hyper, key = "UpArrow", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ mods = hyper, key = "RightArrow", action = act.AdjustPaneSize({ "Right", 5 }) },

		-- navigator
		{ mods = "CTRL", key = "h", action = act.EmitEvent("ActivatePaneDirection-left") },
		{ mods = "CTRL", key = "j", action = act.EmitEvent("ActivatePaneDirection-down") },
		{ mods = "CTRL", key = "k", action = act.EmitEvent("ActivatePaneDirection-up") },
		{ mods = "CTRL", key = "l", action = act.EmitEvent("ActivatePaneDirection-right") },
		{ mods = "CTRL", key = "1", action = act.ActivateTab(0) },
		{ mods = "CTRL", key = "2", action = act.ActivateTab(1) },
		{ mods = "CTRL", key = "3", action = act.ActivateTab(2) },
		{ mods = "CTRL", key = "4", action = act.ActivateTab(3) },
		{ mods = "CTRL", key = "5", action = act.ActivateTab(4) },
		{ mods = "CTRL", key = "6", action = act.ActivateTab(5) },
		{ mods = "CMD", key = "1", action = act.ActivateTab(0) },
		{ mods = "CMD", key = "2", action = act.ActivateTab(1) },
		{ mods = "CMD", key = "3", action = act.ActivateTab(2) },
		{ mods = "CMD", key = "4", action = act.ActivateTab(3) },
		{ mods = "CMD", key = "5", action = act.ActivateTab(4) },
		{ mods = "CMD", key = "6", action = act.ActivateTab(5) },
		{ key = "LeftArrow", mods = "ALT|CMD", action = act.MoveTabRelative(-1) },
		{ key = "RightArrow", mods = "ALT|CMD", action = act.MoveTabRelative(1) },

		-- tabs
		{ key = "F9", action = wezterm.action.ShowTabNavigator }, -- dunno about this one
		{ key = "Tab", mods = "CTRL", action = act.ActivateTabRelative(1) },
		{ key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },

		-- copy mode / hints / quickselect
		-- kitty+e open URL hint
		{
			key = "E",
			mods = hyper,
			action = wezterm.action({
				QuickSelectArgs = {
					patterns = {
						"https?://\\S+",
					},
					action = wezterm.action_callback(function(window, pane)
						local url = window:get_selection_text_for_pane(pane)
						wezterm.open_with(url)
					end),
				},
			}),
		},
		{ key = "F1", action = act.ActivateCopyMode },
		{ mods = hyper, key = "phys:Space", action = act.QuickSelect },

		-- convenience stuff
		{
			mods = "CMD",
			key = "s",
			action = act.Multiple({
				act.SendKey({ key = "\x1b" }), -- escape
				k.multiple_actions(":w"),
			}),
		},
	},

	-- keep defaults
	key_tables = {
		copy_mode = {
			{ key = "Tab", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{ key = "Tab", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "Enter", mods = "NONE", action = act.CopyMode("MoveToStartOfNextLine") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "Space", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "$", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = ",", mods = "NONE", action = act.CopyMode("JumpReverse") },
			{ key = "0", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = ";", mods = "NONE", action = act.CopyMode("JumpAgain") },
			{ key = "F", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
			{ key = "G", mods = "NONE", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
			{ key = "H", mods = "NONE", action = act.CopyMode("MoveToViewportTop") },
			{ key = "H", mods = "SHIFT", action = act.CopyMode("MoveToViewportTop") },
			{ key = "L", mods = "NONE", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "L", mods = "SHIFT", action = act.CopyMode("MoveToViewportBottom") },
			{ key = "M", mods = "NONE", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "M", mods = "SHIFT", action = act.CopyMode("MoveToViewportMiddle") },
			{ key = "O", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "O", mods = "SHIFT", action = act.CopyMode("MoveToSelectionOtherEndHoriz") },
			{ key = "T", mods = "NONE", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },
			{ key = "V", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
			{ key = "^", mods = "NONE", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "b", mods = "NONE", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "b", mods = "CTRL", action = act.CopyMode("PageUp") },
			{ key = "c", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "d", mods = "CTRL", action = act.CopyMode({ MoveByPage = 0.5 }) },
			{ key = "e", mods = "NONE", action = act.CopyMode("MoveForwardWordEnd") },
			{ key = "f", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
			{ key = "f", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "f", mods = "CTRL", action = act.CopyMode("PageDown") },
			{ key = "g", mods = "NONE", action = act.CopyMode("MoveToScrollbackTop") },
			{ key = "g", mods = "CTRL", action = act.CopyMode("Close") },
			{ key = "h", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "j", mods = "NONE", action = act.CopyMode("MoveDown") },
			{ key = "k", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "l", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "m", mods = "ALT", action = act.CopyMode("MoveToStartOfLineContent") },
			{ key = "o", mods = "NONE", action = act.CopyMode("MoveToSelectionOtherEnd") },
			{ key = "q", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "t", mods = "NONE", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
			{ key = "u", mods = "CTRL", action = act.CopyMode({ MoveByPage = -0.5 }) },
			{ key = "v", mods = "NONE", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
			{ key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },
			{ key = "w", mods = "NONE", action = act.CopyMode("MoveForwardWord") },
			{
				key = "y",
				mods = "NONE",
				action = act.Multiple({ { CopyTo = "ClipboardAndPrimarySelection" }, { CopyMode = "Close" } }),
			},
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PageUp") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("PageDown") },
			{ key = "End", mods = "NONE", action = act.CopyMode("MoveToEndOfLineContent") },
			{ key = "Home", mods = "NONE", action = act.CopyMode("MoveToStartOfLine") },
			{ key = "LeftArrow", mods = "NONE", action = act.CopyMode("MoveLeft") },
			{ key = "LeftArrow", mods = "ALT", action = act.CopyMode("MoveBackwardWord") },
			{ key = "RightArrow", mods = "NONE", action = act.CopyMode("MoveRight") },
			{ key = "RightArrow", mods = "ALT", action = act.CopyMode("MoveForwardWord") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("MoveUp") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("MoveDown") },
		},

		search_mode = {
			{ key = "Enter", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "Escape", mods = "NONE", action = act.CopyMode("Close") },
			{ key = "n", mods = "CTRL", action = act.CopyMode("NextMatch") },
			{ key = "p", mods = "CTRL", action = act.CopyMode("PriorMatch") },
			{ key = "r", mods = "CTRL", action = act.CopyMode("CycleMatchType") },
			{ key = "u", mods = "CTRL", action = act.CopyMode("ClearPattern") },
			{ key = "PageUp", mods = "NONE", action = act.CopyMode("PriorMatchPage") },
			{ key = "PageDown", mods = "NONE", action = act.CopyMode("NextMatchPage") },
			{ key = "UpArrow", mods = "NONE", action = act.CopyMode("PriorMatch") },
			{ key = "DownArrow", mods = "NONE", action = act.CopyMode("NextMatch") },
		},
	},
}

-- -- In newer versions of wezterm, use the config_builder which will
-- -- help provide clearer error messages
-- if wezterm.config_builder then
-- 	config = wezterm.config_builder()
-- end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- and finally, return the configuration to wezterm
return config

-- ActivateCommandPalette
-- ActivateCopyMode
-- ActivateKeyTable
-- ActivateLastTab
-- ActivatePaneByIndex
-- ActivatePaneDirection
-- ActivateTab
-- ActivateTabRelative
-- ActivateTabRelativeNoWrap
-- ActivateWindow
-- ActivateWindowRelative
-- ActivateWindowRelativeNoWrap
-- AdjustPaneSize
-- AttachDomain
-- CharSelect
-- ClearKeyTableStack
-- ClearScrollback
-- ClearSelection
-- CloseCurrentPane
-- CloseCurrentTab
-- CompleteSelection
-- CompleteSelectionOrOpenLinkAtMouseCursor
-- Copy
-- CopyTo
-- DecreaseFontSize
-- DetachDomain
-- DisableDefaultAssignment
-- EmitEvent
-- ExtendSelectionToMouseCursor
-- Hide
-- HideApplication
-- IncreaseFontSize
-- InputSelector
-- MoveTab
-- MoveTabRelative
-- Multiple
-- Nop
-- OpenLinkAtMouseCursor
-- PaneSelect
-- Paste
-- PasteFrom
-- PastePrimarySelection
-- PopKeyTable
-- PromptInputLine
-- QuickSelect
-- QuickSelectArgs
-- QuitApplication
-- ReloadConfiguration
-- ResetFontAndWindowSize
-- ResetFontSize
-- ResetTerminal
-- RotatePanes
-- ScrollByCurrentEventWheelDelta
-- ScrollByLine
-- ScrollByPage
-- ScrollToBottom
-- ScrollToPrompt
-- ScrollToTop
-- Search
-- SelectTextAtMouseCursor
-- SendKey
-- SendString
-- SetPaneZoomState
-- Show
-- ShowDebugOverlay
-- ShowLauncher
-- ShowLauncherArgs
-- ShowTabNavigator
-- SpawnCommandInNewTab
-- SpawnCommandInNewWindow
-- SpawnTab
-- SpawnWindow
-- SplitHorizontal
-- SplitPane
-- SplitVertical
-- StartWindowDrag
-- SwitchToWorkspace
-- SwitchWorkspaceRelative
-- ToggleFullScreen
-- TogglePaneZoomState
--
