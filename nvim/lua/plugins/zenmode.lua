---@type LazyPluginSpec
return {
  "folke/zen-mode.nvim",
  keys = {
    {
      "<leader>ez",
      "<CMD> ZenMode <CR>",
      desc = "[z]en mode",
    },
  },
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
}
