---@type LazyPluginSpec[]
return {
  {
    "echasnovski/mini.pairs",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require("mini.pairs").setup()
    end,
  },
}
