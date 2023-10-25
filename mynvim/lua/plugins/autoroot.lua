-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- vim.api.autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })

-- Array of file names indicating root directory. Modify to your liking.
local root_names = { ".git", "package.json" }

-- Cache to use for speed up (at cost of possibly outdated results)
local root_cache = {}

local set_root = function(path)
	-- Get directory path to start search from
	if path == "" then
		return
	end

	-- Try cache and resort to searching upward for root directory
	local root = root_cache[path]

	if root == nil then
		root_file = vim.fs.find(root_names, { path = path, upward = true })[1]
		if root_file == nil then
			return
		end

		root = vim.fs.dirname(root_file)

		root_cache[path] = root
	end

	-- Set current directory
	vim.fn.chdir(root)
end

local session_cache = {}
local set_session = function()
	-- print "HELLO"
	-- Get directory path to start search from
	local path = vim.fn.getcwd()

	-- local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return
	end

	session = string.match(path, "/(%w+)$")
	if require("possession.session").exists(session) then
		require("possession.session").load(session)
	end
end

local root_augroup = vim.api.nvim_create_augroup("MyAutoRoot", {})

vim.api.nvim_create_autocmd("BufEnter", {
	group = root_augroup,
	callback = function(ev)
		set_root(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = root_augroup,
	callback = function()
		set_root(vim.fn.getcwd())
		vim.schedule(function()
			set_session()
		end)
	end,
})
