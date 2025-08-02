---@type LazyPluginSpec
return {
  "MagicDuck/grug-far.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>rw",
      function()
        require("grug-far").open()
      end,
      desc = "Find+Replace [w]ord",
      mode = "n",
    },
  },
  config = function()
    require("grug-far").setup {
      -- options, see Configuration section below
      -- there are no required options atm
      -- engine = 'ripgrep' is default, but 'astgrep' can be specified
    }
  end,
}
