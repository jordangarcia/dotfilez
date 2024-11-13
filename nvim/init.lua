require "core"

-- bootstrap/install lazy.nvim!
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").install(lazypath)
end

vim.opt.rtp:prepend(lazypath)

-- load plugins
require("lazy").setup {
  change_detection = { enabled = false },
  defaults = {
    lazy = true,
  },
  install = { colorscheme = { "kanagawa" } },
  spec = {
    { import = "core.plugins" },
    { import = "plugins" },
  },
}
