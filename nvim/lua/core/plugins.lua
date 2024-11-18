---@type LazyPluginSpec[]
return {
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
  },

  {
    "norcalli/nvim-colorizer.lua",
    lazy = false,
    ft = { "css", "lua" },
    event = "VeryLazy",
    config = function(_, opts)
      require("colorizer").setup { user_default_options = { names = false, css = true } }
    end,
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
