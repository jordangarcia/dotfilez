local null_ls = require "null-ls"

local h = require "null-ls.helpers"
local u = require "null-ls.utils"

local eslint = require("null-ls").builtins.diagnostics.eslint_d.with {
  cwd = h.cache.by_bufnr(function(params)
    local cwd = u.root_pattern ".git"(params.bufname)
    return cwd
  end),
}

local opts = {
  debug = true,
  sources = {
    -- null_ls.builtins.diagnostics.eslint_d,
    eslint,
    -- null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    if client.supports_method "textDocument/formatting" then
      local augroup = vim.api.nvim_create_augroup("Format", {})

      vim.api.nvim_clear_autocmds {
        group = augroup,
        buffer = bufnr,
      }
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
}

null_ls.setup(opts)
