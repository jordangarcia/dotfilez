local opt = vim.opt
local g = vim.g
local config = require "core.chadrc"

-------------------------------------- globals -----------------------------------------
g.nvchad_theme = config.ui.theme
g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
g.toggle_theme_icon = "   "
g.transparency = config.ui.transparency

-------------------------------------- options ------------------------------------------
g.mapleader = " "

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

vim.cmd [[
  set listchars=""          " Reset the listchars
  set listchars=tab:\ \     " a tab should display as "  ", trailing whitespace as "."
  set listchars+=trail:.    " show trailing spaces as dots
  set listchars+=extends:>  " The character to show in the last column when wrap is
                            " off and the line continues beyond the right of the screen
  set listchars+=precedes:< " The character to show in the last column when wrap is
                            " off and the line continues beyond the right of the screen
]]

-- pmenu
opt.pumblend = 10 -- Popup blend
opt.pumheight = 7
opt.pumwidth = 30

opt.splitbelow = true
opt.number = true
opt.rnu = true

-- opt.wrap = false
vim.cmd [[ set wrap linebreak nolist ]]
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

opt.fillchars = { eob = " " }
opt.ignorecase = true
opt.smartcase = true
opt.mouse = "a"

-- Numbers
opt.number = true
opt.numberwidth = 2
opt.ruler = false

-- disable nvim intro
opt.shortmess:append "sI"

opt.signcolumn = "yes"
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
