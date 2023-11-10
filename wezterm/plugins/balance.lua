-- balance.lua

local wezterm = require("wezterm")
local M = {}

--- walk panes that are on the same axis as the tab's active pane
local function walk_siblings(axis, tab, window, pane, do_func)
	local initial_pane = pane
	local siblings = { (do_func and do_func(initial_pane) or initial_pane) }
	local prev_dir = axis == "x" and "Left" or "Up"
	local next_dir = axis == "x" and "Right" or "Down"
	local max_iter = 20 -- prevent infinite loops (increase if need be)

	local initial_pane_idx = 1
	local panes_info = tab:panes_with_info()
	for _, pi in ipairs(panes_info) do
		if pi.is_active then
			initial_pane_idx = pi.index
		end
	end

	-- [[DEBUG
	wezterm.log_info(string.format("initial pane: %s", tab:active_pane()))
	--]]

	-- loop on siblings backward and forward, starting from initial pane
	for _, step_dir in ipairs({ "prev", "next" }) do
		-- [[DEBUG
		wezterm.log_info(string.format("checking %s siblings", step_dir))
		--]]

		local last_pane = tab:active_pane()
		window:perform_action(
			wezterm.action.ActivatePaneDirection(step_dir == "prev" and prev_dir or next_dir),
			tab:active_pane()
		)
		-- [[DEBUG
		wezterm.log_info(string.format("new active pane: %s", tab:active_pane()))
		--]]
		local new_pane = tab:active_pane()

		local i = 0
		while new_pane:pane_id() ~= last_pane:pane_id() and i < max_iter do
			if step_dir == "prev" then
				table.insert(siblings, 1, (do_func and do_func(new_pane) or new_pane))
			else
				table.insert(siblings, (do_func and do_func(new_pane) or new_pane))
			end
			last_pane = tab:active_pane()
			window:perform_action(
				wezterm.action.ActivatePaneDirection(step_dir == "prev" and prev_dir or next_dir),
				tab:active_pane()
			)
			new_pane = tab:active_pane()
			-- [[DEBUG
			wezterm.log_info(string.format("new active pane: %s", tab:active_pane()))
			--]]
			i = i + 1
		end

		-- back to initial pane
		window:perform_action(wezterm.action.ActivatePaneByIndex(initial_pane_idx), tab:active_pane())
		-- [[DEBUG
		wezterm.log_info(string.format("back to initial pane: %s", tab:active_pane()))
		--]]
	end

	return siblings
end

function M.sibling_counts(window, pane)
	print("sibling_counts" .. pane:pane_id())
	local tab = window:active_tab()
	local ysiblings = walk_siblings("y", tab, window, pane)
	local xsiblings = walk_siblings("x", tab, window, pane)

	return {
		y = #ysiblings,
		x = #xsiblings,
	}
end

function M.close_direction()
	return function(window, pane)
		local tab = window:active_tab()
		local up = tab:get_pane_direction("Up")
		local down = tab:get_pane_direction("Down")
		local ypane = up or down
		if ypane then
			return { dir = "y", pane = ypane }
		end
		local left = tab:get_pane_direction("Left")
		local right = tab:get_pane_direction("Right")
		local xpane = left or right
		print("xpane: ", xpane)
		if xpane then
			return { dir = "x", pane = xpane }
		end
	end
end

function M.balance_panes(axis)
	return function(window, pane)
		local tab = window:active_tab()
		local initial_pane = pane
		local prev_dir = axis == "x" and "Left" or "Up"
		local next_dir = axis == "x" and "Right" or "Down"
		local siblings = walk_siblings(axis, tab, window, pane)
		local tab_size = tab:get_size()[axis == "x" and "cols" or "rows"]
		local balanced_size = math.floor(tab_size / #siblings)
		local pane_size_key = axis == "x" and "cols" or "viewport_rows"

		wezterm.log_info(string.format("resizing %s panes on %s axis to %s cells", #siblings, axis, balanced_size))

		walk_siblings(axis, tab, window, pane, function(pane)
			local pane_size = pane:get_dimensions()[pane_size_key]
			local adj_amount = pane_size - balanced_size
			local adj_dir = adj_amount < 0 and next_dir or prev_dir
			adj_amount = math.abs(adj_amount)
			wezterm.log_info(
				string.format(
					"adjusting pane [%s] from %s by %s cells %s",
					pane,
					tostring(pane_size),
					tostring(adj_amount),
					adj_dir
				)
			)
			window:perform_action(wezterm.action.AdjustPaneSize({ adj_dir, adj_amount }), pane)
		end)
	end
end

wezterm.on("augment-command-palette", function()
	return {
		{
			brief = "Balance panes horizontally",
			action = wezterm.action_callback(M.balance_panes("x")),
		},
		{
			brief = "Balance panes vertically",
			action = wezterm.action_callback(M.balance_panes("y")),
		},
	}
end)

return M
