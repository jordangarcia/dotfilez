---@type LazyPluginSpec[]
return {
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup {
        move_cursor = false,
        -- Configuration here, or leave empty to use defaults
      }
    end,
  },

  {
    "tpope/vim-surround",
    enabled = false,
    event = "VeryLazy",
  },
}
