local autocmd = vim.api.nvim_create_autocmd

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- truncate LSP log if > 1MB
local lsp_log = vim.lsp.get_log_path()
if vim.fn.getfsize(lsp_log) > 1024 * 1024 then
  vim.fn.writefile({}, lsp_log)
end

-- dont list quickfix buffers
autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.opt_local.buflisted = false
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "signature",
  callback = function()
    vim.opt_local.winbar = nil
  end,
})
-- Auto resize panes when resizing nvim window
autocmd("VimResized", {
  pattern = "*",
  callback = function()
    -- get current tab and run winc =
    vim.cmd "wincmd ="
  end,
})

autocmd("BufReadPost", {
  pattern = "fugitive://*",
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
  group = vim.api.nvim_create_augroup("close_fugitive_with_q", { clear = true }),
})

autocmd("FileType", {
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
    "fugitiveblame",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- fix for session restore + noice
autocmd("TabEnter", {
  callback = function(opts)
    vim.cmd [[ set cmdheight=0 ]]
  end,
})
-- reload some chadrc options on-save
-- autocmd("BufWritePost", {
--   pattern = vim.tbl_map(function(path)
--     return vim.fs.normalize(vim.loop.fs_realpath(path))
--   end, vim.fn.glob(vim.fn.stdpath "config" .. "/lua/core/**/*.lua", true, true, true)),
--   group = vim.api.nvim_create_augroup("ReloadNvChad", {}),
--
--   callback = function(opts)
--     local fp = vim.fn.fnamemodify(vim.fs.normalize(vim.api.nvim_buf_get_name(opts.buf)), ":r") --[[@as string]]
--     local app_name = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME or "nvim"
--     local module = string.gsub(fp, "^.*/" .. app_name .. "/lua/", ""):gsub("/", ".")
--     print("reload" .. module)
--
--     require("plenary.reload").reload_module "base46"
--     require("plenary.reload").reload_module(module)
--     require("plenary.reload").reload_module "core.chadrc"
--
--     config = require("core.utils").load_config()
--
--     vim.g.nvchad_theme = config.ui.theme
--     vim.g.transparency = config.ui.transparency
--
--     -- statusline
--     require("plenary.reload").reload_module("nvchad.statusline." .. config.ui.statusline.theme)
--     vim.opt.statusline = "%!v:lua.require('nvchad.statusline." .. config.ui.statusline.theme .. "').run()"
--
--     -- tabufline
--     if config.ui.tabufline.enabled then
--       require("plenary.reload").reload_module "nvchad.tabufline.modules"
--       vim.opt.tabline = "%!v:lua.require('nvchad.tabufline.modules').run()"
--     end
--
--     require("base46").load_all_highlights()
--     -- vim.cmd("redraw!")
--   end,
-- })

-- Disable folding in Telescope's result window.
-- vim.api.nvim_create_autocmd("FileType", { pattern = "TelescopeResults", command = [[setlocal nofoldenable]] })

-- disable syntax highlighting for large files
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function(args)
    local file_size = vim.fn.getfsize(args.file)
    -- Disable syntax for files > 1MB
    if file_size > 1024 * 1024 * 5 then
      vim.opt_local.synmaxcol = 0
      vim.cmd "syntax off"
      vim.cmd "TSBufDisable highlight"
    end
  end,
})
-- user event that loads after UIEnter + only if file buf is there
