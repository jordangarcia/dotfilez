---@type LazyPluginSpec
return {
  "lukas-reineke/indent-blankline.nvim",
  enabled = true,
  lazy = false,
  main = "ibl",
  opts = {
    indent = {
      char = "▏",
    },
    scope = {
      enabled = false,
      show_start = true,
      show_end = false,
    },
    exclude = {
      filetypes = {
        "help",
        "terminal",
        "lazy",
        "lspinfo",
        "TelescopePrompt",
        "TelescopeResults",
        "mason",
        "nvdash",
        "nvcheatsheet",
        "noice",
      },
      buftypes = {
        "terminal",
        "noice",
      },
    },
  },

  config = function(_, opts)
    require("ibl").setup(opts)
    local hooks = require "ibl.hooks"
    hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
  end,
}
