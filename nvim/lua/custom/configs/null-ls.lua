local null_ls = require "null-ls"

local opts = {
  debug = true,
  sources = {
    null_ls.builtins.formatting.prettier.with {
      filetypes = {
        "typescriptreact",
        "javascript",
        "typescript",
        "css",
        "scss",
        "html",
        "json",
        "jsonc",
        "yaml",
        "markdown",
        "graphql",
        "md",
        "txt",
      },
    },
    null_ls.builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    -- this is buggy, instead just setup an auto cmd for EVERYTHING
    -- that saves
    -- if client.supports_method "textDocument/formatting" then
    --   local augroup = vim.api.nvim_create_augroup("Format", {})
    --
    --   vim.api.nvim_clear_autocmds {
    --     group = augroup,
    --     buffer = bufnr,
    --   }
    --   vim.api.nvim_create_autocmd("BufWritePre", {
    --     group = augroup,
    --     buffer = bufnr,
    --     callback = function()
    --       print("null ls formatting" .. bufnr)
    --       vim.lsp.buf.format { bufnr = bufnr, async = false }
    --     end,
    --   })
    -- end
  end,
}

null_ls.setup(opts)

vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(ev)
    vim.lsp.buf.format { bufnr = ev.buf, async = false }
  end,
})
