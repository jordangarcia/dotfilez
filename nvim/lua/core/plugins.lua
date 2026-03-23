---@type LazyPluginSpec[]
return {
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },


  -- {
  --   "nvim-tree/nvim-web-devicons",
  --   lazy = false,
  -- },

  {
    "echasnovski/mini.icons",
    enabled = true,
    version = "*",
    lazy = false,
    config = function()
      require("mini.icons").setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
}
