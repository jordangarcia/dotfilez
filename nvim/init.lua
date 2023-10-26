-------------------------------------- globals -----------------------------------------
-- vim.g.nvchad_theme = config.ui.theme
-- vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.toggle_theme_icon = "   "
vim.g.transparency = false
vim.opt.swapfile = false

-------------------------------------- options ------------------------------------------
vim.g.mapleader = ","
vim.opt.laststatus = 3 -- global statusline
vim.opt.showmode = false

vim.opt.linespace = 0
vim.opt.clipboard = "unnamed"
vim.opt.cursorline = true

-- Indenting
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.scrolljump = 5
vim.opt.scrolloff = 3
vim.opt.autoindent = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2

vim.opt.fillchars = { eob = " " }
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.mouse = "a"

-- Numbers
-- opt.number = true
vim.opt.rnu = true
vim.opt.numberwidth = 2
vim.opt.ruler = false

-- pmenu
vim.opt.pumheight = 7
vim.opt.pumwidth = 20
--

-- disable nvim intro
-- vim.opt.shortmess:append "sI"

vim.opt.signcolumn = "yes"
vim.opt.splitbelow = false
vim.opt.splitright = true
vim.opt.termguicolors = true
vim.opt.timeoutlen = 400
vim.opt.undofile = true
vim.opt.wrap = false

-- interval for writing swap file to disk, also used by gitsigns
vim.opt.updatetime = 250

-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
vim.opt.whichwrap:append "<>[]hl"

-- disable some default providers
for _, provider in ipairs { "node", "perl", "python3", "ruby" } do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

-------------------------------------- autocmds ------------------------------------------

-- dont list quickfix buffers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

-- do install
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("bootstrap").lazy(lazypath)
end

require("utils").load_mappings "general"

-- install plugins
vim.opt.rtp:prepend(lazypath)
require "plugins"

vim.cmd.colorscheme "catppuccin"
