---@type LazyPluginSpec
return {
  "lukas-reineke/indent-blankline.nvim",
  enabled = false,
  main = "ibl",
  opts = {
    indent = {
      char = "▏",
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
}
