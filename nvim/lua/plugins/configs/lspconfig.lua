-- dofile(vim.g.base46_cache .. "lsp")
-- require "nvchad.lsp"
local lspconfig = require "lspconfig"

local M = {}

-- export on_attach & capabilities for custom lspconfigs
--
M.on_attach_no_formatting = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
  --
  -- if client.server_capabilities.signatureHelpProvider then
  --   require("nvchad.signature").setup(client)
  -- end
end

M.on_attach = function(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
  client.server_capabilities.documentRangeFormattingProvider = false
  --
  -- if client.server_capabilities.signatureHelpProvider then
  --   require("nvchad.signature").setup(client)
  -- end
end

local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

local capabilities = vim.tbl_deep_extend(
  "force",
  {},
  vim.lsp.protocol.make_client_capabilities(),
  has_cmp and cmp_nvim_lsp.default_capabilities() or {}
)

M.capabilities = capabilities

-- M.capabilities = vim.lsp.protocol.make_client_capabilities()
--
-- M.capabilities.textDocument.completion.completionItem = {
--   documentationFormat = { "markdown", "plaintext" },
--   snippetSupport = true,
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
--
-- Lua language server migrated to native LSP (see lsp/lua_ls.lua)

-- Migrated to native LSP (see lsp/*.lua files)

-- Migrated to native LSP (see lsp/terraformls.lua)

-- Python servers migrated to native LSP (see lsp/pyright.lua and lsp/ruff.lua)

-- Native LSP servers are enabled in plugins/lsp.lua

-- vtsls migrated to native LSP (see lsp/vtsls.lua)
-- Note: Still need to require vtsls plugin for the language server binary
require("lspconfig.configs").vtsls = require("vtsls").lspconfig

vim.diagnostic.config {
  virtual_text = false,
}

-- dont show hints in sidebar
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "LineNr", numhl = "" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "LineNr", numhl = "" })

return M
