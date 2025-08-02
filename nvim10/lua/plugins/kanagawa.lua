---@type LazyPluginSpec
return {
  "rebelot/kanagawa.nvim",
  enabled = false,
  lazy = false,
  config = function(self, opts)
    vim.cmd [[ colorscheme kanagawa ]]
  end,
}
