local find_neovim_config = function()
	require("telescope.builtin").find_files({
		prompt_title = "~ neovim config ~",
		shorten_path = false,
		cwd = "~/.config/nvim",
		width = 0.25,
		layout_strategy = "horizontal",
		layout_config = {
			preview_width = 0.65,
		},
	})
end

vim.api.nvim_create_user_command("FindConfig", find_neovim_config, {})
