local colors = require("core.highlights").palette
---@type LazyPluginSpec
return {
  "petertriho/nvim-scrollbar",
  event = "VeryLazy",
  config = function()
    require("scrollbar").setup {
      marks = {
        Hint = {
          priority = -1,
          color = colors.sumiInk3,
          -- text = { "█" },
        },
      },
      excluded_filetypes = {
        "cmp_docs",
        "cmp_menu",
        "noice",
        "prompt",
        "TelescopePrompt",
        "NvimTree",
      },

      handlers = {
        cursor = false,
      },
    }
  end,
}
