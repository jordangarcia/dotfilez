-- Minimal scrollback viewer for kitty-scrollback.nvim
vim.g.scrollback = true

local opt = vim.opt

-- Leader
vim.g.mapleader = " "

-- No line numbers
opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"

-- No UI chrome
opt.laststatus = 0
opt.showtabline = 0
opt.winbar = nil
opt.ruler = false
opt.showmode = false
opt.showcmd = false
opt.statuscolumn = ""

-- Clean display
opt.fillchars = { eob = " " }
opt.shortmess:append "I"

-- Clipboard for yanking
opt.clipboard = "unnamedplus"

-- No spell
opt.spell = false

-- Scrolling
opt.scrolloff = 999
opt.scrolljump = 5
opt.sidescrolloff = 8

-- q to quit
vim.keymap.set("n", "q", "<cmd>q!<CR>", { silent = true })

-- Faster scrolling
vim.keymap.set("n", "<C-e>", "5<C-e>", {})
vim.keymap.set("n", "<C-y>", "5<C-y>", {})

-- vim-kitty-navigator
vim.keymap.set("n", "<C-h>", "<CMD>KittyNavigateLeft<CR>", { silent = true })
vim.keymap.set("n", "<C-j>", "<CMD>KittyNavigateDown<CR>", { silent = true })
vim.keymap.set("n", "<C-k>", "<CMD>KittyNavigateUp<CR>", { silent = true })
vim.keymap.set("n", "<C-l>", "<CMD>KittyNavigateRight<CR>", { silent = true })

-- kitty-scrollback yank and quit
vim.keymap.set("v", "y", "<Plug>(KsbVisualYank)<Plug>(KsbQuitAll)", { silent = true, remap = true })
vim.keymap.set("n", "Y", "<Plug>(KsbNormalYankEnd)<Plug>(KsbQuitAll)", { silent = true, remap = true })

-- Load colorscheme
require "kanagawa"

-- Load plugins from lazy path
vim.opt.runtimepath:append(vim.fn.stdpath "data" .. "/lazy/kitty-scrollback.nvim")
vim.opt.runtimepath:append(vim.fn.stdpath "data" .. "/lazy/vim-kitty-navigator")
require("kitty-scrollback").setup {}
