require "core"

-- bootstrap/install lazy.nvim!
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)

-- load plugins
require("lazy").setup {
  spec = {
    { import = "core.plugins" },
    { import = "plugins" },
  },
}
