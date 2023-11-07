-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "tabdo wincmd =",
})

-- vim.g.clipboard = "unnamed"
vim.opt.swapfile = false

-- pmenu
vim.opt.pumheight = 7
vim.opt.pumwidth = 20

vim.opt.splitbelow = false
vim.opt.number = false
vim.opt.rnu = true

vim.opt.wrap = false
vim.opt.scrolljump = 5
vim.opt.scrolloff = 3
vim.opt.autochdir = false

vim.cmd [[set path+="/opt/homebrew/bin"]]
