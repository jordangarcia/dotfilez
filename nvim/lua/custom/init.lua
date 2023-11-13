-- local autocmd = vim.api.nvim_create_autocmd
--

-- Auto resize panes when resizing nvim window
local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("VimResized", {
  pattern = "*",
  command = "tabdo wincmd =",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup "close_with_q",
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "query",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- vim.g.clipboard = "unnamed"
vim.opt.swapfile = false

vim.opt.list = true -- Show some invisible characters (tabs...
-- pmenu
vim.opt.pumblend = 10 -- Popup blend
vim.opt.pumheight = 7
vim.opt.pumwidth = 20

vim.opt.splitbelow = true
vim.opt.number = true
vim.opt.rnu = true

vim.opt.wrap = false
vim.opt.scrolljump = 5
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8 -- Columns of context
vim.opt.autochdir = false

vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.winminwidth = 5 -- Minimum window width
vim.cmd [[set path+="/opt/homebrew/bin"]]
