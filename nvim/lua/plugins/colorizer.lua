---@type LazyPluginSpec
return {
  "norcalli/nvim-colorizer.lua",
  lazy = false,
  ft = { "css", "lua" },
  event = "VeryLazy",
  keys = {
    { "<leader>uC", "<cmd>ColorizerToggle<CR>", desc = "Toggle colorizer" },
  },
  config = function(_, opts)
    require("colorizer").setup { user_default_options = { names = false, css = true } }
  end,
}
