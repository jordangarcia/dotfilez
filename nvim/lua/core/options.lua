local opt = vim.opt
local g = vim.g
local o = vim.o
local config = require "core.chadrc"

-------------------------------------- globals -----------------------------------------
g.nvchad_theme = config.ui.theme
g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
g.toggle_theme_icon = "   "
g.transparency = config.ui.transparency

-------------------------------------- options ------------------------------------------
g.mapleader = " "

-- disable netrw
g.loaded_netrwPlugin = 1
g.loaded_netrw = 1

opt.laststatus = 3 -- global statusline
opt.showmode = false

opt.clipboard = "unnamedplus"
opt.cursorline = false

-- Indenting
opt.expandtab = true
opt.shiftwidth = 2
opt.smartindent = true
opt.tabstop = 2
opt.softtabstop = 2
-- vim.g.clipboard = "unnamed"
opt.swapfile = false

opt.list = true -- Show some invisible characters (tabs...

-- pmenu
opt.pumblend = 0 -- Popup blend
opt.pumheight = 20
opt.pumwidth = 30

opt.splitbelow = true
opt.number = true
opt.rnu = true

opt.wrap = false
-- vim.cmd [[ set wrap linebreak nolist ]]
opt.scrolljump = 5
-- go to previous/next line with h,l,left arrow and right arrow
-- when cursor reaches end/beginning of line
opt.whichwrap:append "<>[]hl"
opt.scrolloff = 4
opt.sidescrolloff = 8 -- Columns of context
opt.autochdir = false

-- this is for edgy
opt.splitkeep = "screen"
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width

vim.cmd [[
  set listchars=""          " Reset the listchars
  set listchars=tab:\ \     " a tab should display as "  ", trailing whitespace as "."
  set listchars+=trail:.    " show trailing spaces as dots
]]
opt.fillchars = {
  eob = " ",
  vert = "🮊",
  vertright = "🮊",
  vertleft = "🮊",
}
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.numberwidth = 2
opt.ruler = false

-- tabline
o.showtabline = 2

-- disable nvim intro
opt.shortmess:append "sI"

-- signcolumn
opt.signcolumn = "yes"
if vim.fn.has "nvim-0.9.0" == 1 then
  vim.opt.statuscolumn = [[%!v:lua.require'custom.statuscolumn'.statuscolumn()]]
end
opt.splitright = true
opt.termguicolors = true
opt.timeoutlen = 400
opt.undofile = true

-- interval for writing swap file to disk, also used by gitsigns
opt.updatetime = 250

-- disable some default providers
for _, provider in ipairs { "node", "perl", "python3", "ruby" } do
  vim.g["loaded_" .. provider .. "_provider"] = 0
end

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
local sep = (is_windows and ";" or ":")
local mason_path = vim.fn.stdpath "data" .. "/mason/bin"

vim.env.PATH = mason_path .. sep .. vim.env.PATH
vim.env.PATH = "/opt/homebrew/bin" .. sep .. vim.env.PATH
