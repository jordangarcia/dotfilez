---@type LazyPluginSpec
return {
  "lukas-reineke/indent-blankline.nvim",
  version = "2.20.7",
  init = function()
    require("core.utils").lazy_load "indent-blankline.nvim"
  end,
  opts = {
    indentLine_enabled = 1,
    filetype_exclude = {
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
      "",
    },
    buftype_exclude = { "terminal", "noice" },
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
    show_current_context = true,
    show_current_context_start = false,
  },
  config = function(_, opts)
    dofile(vim.g.base46_cache .. "blankline")
    require("indent_blankline").setup(opts)
  end,
}
