local M = {}

M.echo = function(str)
  vim.cmd "redraw"
  vim.api.nvim_echo({ { str, "Bold" } }, true, {})
end
local function shell_call(args)
	local output = vim.fn.system(args)
	assert(vim.v.shell_error == 0, "External call failed with error code: " .. vim.v.shell_error .. "\n" .. output)
end

M.lazy = function(install_path)
	--------- lazy.nvim ---------------
	M.echo("  Installing lazy.nvim & plugins ...")
	local repo = "https://github.com/folke/lazy.nvim.git"
	shell_call({ "git", "clone", "--filter=blob:none", "--branch=stable", repo, install_path })
	vim.opt.rtp:prepend(install_path)

	-- install plugins
	require("plugins")

	-- mason packages
	-- return function()

	vim.schedule(function()
		vim.cmd("MasonInstallAll")

		-- Keep track of which mason pkgs get installed
		local packages = table.concat(vim.g.mason_binaries_list, " ")

		require("mason-registry"):on("package:install:success", function(pkg)
			packages = string.gsub(packages, pkg.name:gsub("%-", "%%-"), "") -- rm package name

			-- run above screen func after all pkgs are installed.
			if packages:match("%S") == nil then
				vim.schedule(function()
					vim.api.nvim_buf_delete(0, { force = true })
					vim.cmd("echo '' | redraw") -- clear cmdline
					print("DONE")
				end)
			end
		end)
	end)
end

return M