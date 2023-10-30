local M = {}

local protocol = require "vim.lsp.protocol"

-- global opts
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
  update_in_insert = false,
  -- virtual_text = { spacing = 4, prefix = "\u{ea71}" },
  severity_sort = true,
  virtual_text = false,
})

vim.diagnostic.config {
  virtual_text = false,
}

local augroup_format = vim.api.nvim_create_augroup("Format", { clear = true })
local enable_format_on_save = function(_, bufnr)
  vim.api.nvim_clear_autocmds { group = augroup_format, buffer = bufnr }
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup_format,
    buffer = bufnr,
    callback = function()
      vim.lsp.buf.format { bufnr = bufnr }
    end,
  })
end

protocol.CompletionItemKind = {
  "", -- Text
  "", -- Method
  "", -- Function
  "", -- Constructor
  "", -- Field
  "", -- Variable
  "", -- Class
  "ﰮ", -- Interface
  "", -- Module
  "", -- Property
  "", -- Unit
  "", -- Value
  "", -- Enum
  "", -- Keyword
  "﬌", -- Snippet
  "", -- Color
  "", -- File
  "", -- Reference
  "", -- Folder
  "", -- EnumMember
  "", -- Constant
  "", -- Struct
  "", -- Event
  "ﬦ", -- Operator
  "", -- TypeParameter
}

-- export on_attach & capabilities for custom lspconfigs
M.on_attach = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvinder = false
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()

-- M.capabilities.textDocument.completion.completionItem = {
--   documentationFormat = { "markdown", "plaintext" },
--   snippetSupport = false,
--   preselectSupport = true,
--   insertReplaceSupport = true,
--   labelDetailsSupport = true,
--   deprecatedSupport = true,
--   commitCharactersSupport = true,
--   tagSupport = { valueSet = { 1 } },
--   resolveSupport = {
--     properties = {
--       "documentation",
--       "detail",
--       "additionalTextEdits",
--     },
--   },
-- }

local lspconfig = require "lspconfig"
lspconfig.lua_ls.setup {
  on_attach = M.on_attach,
  capabilities = M.capabilities,

  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
          [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}

local servers = { "html", "cssls", "prismals" }

lspconfig["graphql"].setup {
  on_attach = M.on_attach,
  capabilities = M.capabilities,
  root_dir = require("lspconfig.util").root_pattern "package.json",
}

-- lspconfig["tsserver"].setup {
--   on_attach = function(client, bufnr)
--     require("utils").load_mappings("lspconfig", { buffer = bufnr })
--     enable_format_on_save(client, bufnr)
--   end,
--   capabilities = M.capabilities,
-- }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = M.on_attach,
    capabilities = M.capabilities,
  }
end

local signs = { Error = "", Warn = "", Hint = "*", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "ErrorMessage" })
end

-- vim.cmd [[hi DiagnosticUnderlineError cterm=undercurl gui=undercurl guisp=#ff0000]]

return M
