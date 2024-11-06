return {
  "syntax-highlighting",
  dev = true,
  lazy = false,
  config = function()
    dofile(vim.g.base46_cache .. "syntax")
  end,
}
