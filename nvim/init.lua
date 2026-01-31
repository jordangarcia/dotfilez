-- Check for scrollback mode (launched from kitty)
if vim.env.NVIM_SCROLLBACK == "1" then
  require "init_scrollback"
  return
end

require "core.options"
require "core.keymaps"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require "core.autocmds"
require "core.filetypes"
require "kanagawa"
require("custom.winbar").setup()

-- load plugins
require("lazy").setup {
  change_detection = { enabled = false },
  defaults = {
    lazy = true,
  },
  install = { colorscheme = { "kanagawa" } },
  dev = {
    path = "~/code/",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
    fallback = false, -- Fallback to git when local plugin doesn't exist
  },
  spec = {
    { import = "core.plugins" },
    { import = "plugins" },
  },
}
