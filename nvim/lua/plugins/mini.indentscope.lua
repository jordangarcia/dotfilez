---@type LazyPluginSpec
return {
  "echasnovski/mini.indentscope",
  version = "*",
  lazy = true,
  event = "VeryLazy",
  config = function()
    require("mini.indentscope").setup {
      symbol = "│",
      draw = {
        animation = require("mini.indentscope").gen_animation.none(),
      },
    }
  end,
}
