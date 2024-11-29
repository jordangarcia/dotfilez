local wezterm = require("wezterm")
local mux = wezterm.mux
local M = {}

local function dir(name)
	return wezterm.home_dir .. "/code/" .. name
end

M.setup_gamma = function()
	local dir_code = dir("")
	local dir_dotfilez = dir("dotfilez")
	local dir_gamma = dir("gamma")
	local dir_server = dir("gamma/packages/server")
	local dir_client = dir("gamma/packages/client")
	local dir_hocus = dir("gamma/packages/hocuspocus")

	local tab, main_pane, window = mux.spawn_window({
		cwd = dir_code,
	})
	tab:set_title("scratch")

	local tab2, pane2 = window:spawn_tab({ cwd = dir_server })
	tab2:set_title("server")

	local tab3, pane3 = window:spawn_tab({ cwd = dir_client })
	tab3:set_title("client")

	local tab4, pane4 = window:spawn_tab({ cwd = dir_server })
	tab4:set_title("dev")

	local pane42 = pane4:split({ direction = "Right", cwd = dir_client })
	local pane43 = pane42:split({ direction = "Bottom", cwd = dir_hocus })

	-- send enter + clear to get rid of direnv spam
	pane4:send_text("\nclear\n")
	pane42:send_text("\nclear\n")
	pane43:send_text("\nclear\n")

	pane4:send_text("yarn dev:no-kafka\n")
	pane42:send_text("yarn dev:light:turbo\n")
	pane43:send_text("yarn dev\n")

	local tab5, pane5 = window:spawn_tab({ cwd = dir_dotfilez })
	tab5:set_title("hocus")

	local tab6, pane6 = window:spawn_tab({ cwd = dir_code })
	tab5:set_title("code")
end

return M
