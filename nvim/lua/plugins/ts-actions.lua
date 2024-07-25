---@type LazyPluginSpec[]
return {
  {
    "jordangarcia/ts-actions.nvim",
    dir = "~/code/ts-actions.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>pr",
        function()
          vim.cmd [[ source /Users/jordan/code/dotfilez/nvim/lua/plugins/custom/ts-actions.lua ]]
        end,
        desc = "reload plugin",
        mode = "n",
      },

      {
        "<C-S-n>",
        function()
          require("ts-actions").prev()
        end,
        desc = "[p]rev",
        mode = "n",
      },
      {
        "<C-n>",
        function()
          require("ts-actions").next()
        end,
        desc = "[n]ext",
        mode = "n",
      },
    },
    dependencies = {
      { "MunifTanjim/nui.nvim", lazy = true },
    },

    config = function()
      require "plugins.custom.ts-actions"
    end,
  },
}
