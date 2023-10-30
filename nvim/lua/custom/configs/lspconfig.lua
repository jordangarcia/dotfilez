local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table

lspconfig["graphql"].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = require("lspconfig.util").root_pattern "package.json",
}

local servers = { "html", "cssls", "prismals"}
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

vim.diagnostic.config {
  virtual_text = false,
}

-- dont show hints in sidebar 
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "LineNr", numhl="" })
--
-- lspconfig.pyright.setup { blabla}
