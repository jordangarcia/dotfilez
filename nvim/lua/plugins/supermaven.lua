---@type LazyPluginSpec[]
return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "VeryLazy",
    config = function()
      require("supermaven-nvim").setup {
        log_level = "off",

        keymaps = {
          accept_suggestion = "<C-l>",
          accept_word = "<C-j",
          clear_suggestion = "<C-e>",
        },
      }
    end,
  },
}
