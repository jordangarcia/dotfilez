local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table

lspconfig["graphql"].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = require("lspconfig.util").root_pattern "package.json",
}
lspconfig["eslint"].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  root_dir = require("lspconfig.util").root_pattern ".git",
}
lspconfig["jsonls"].setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    json = {
      -- Schemas https://www.schemastore.org
      schemas = {
        {
          fileMatch = { "package.json" },
          url = "https://json.schemastore.org/package.json",
        },
        {
          fileMatch = { "tsconfig*.json" },
          url = "https://json.schemastore.org/tsconfig.json",
        },
        {
          fileMatch = {
            ".prettierrc",
            ".prettierrc.json",
            "prettier.config.json",
          },
          url = "https://json.schemastore.org/prettierrc.json",
        },
        {
          fileMatch = { ".eslintrc", ".eslintrc.json" },
          url = "https://json.schemastore.org/eslintrc.json",
        },
        {
          fileMatch = { ".babelrc", ".babelrc.json", "babel.config.json" },
          url = "https://json.schemastore.org/babelrc.json",
        },
        {
          fileMatch = { "lerna.json" },
          url = "https://json.schemastore.org/lerna.json",
        },
        {
          fileMatch = { "now.json", "vercel.json" },
          url = "https://json.schemastore.org/now.json",
        },
        {
          fileMatch = {
            ".stylelintrc",
            ".stylelintrc.json",
            "stylelint.config.json",
          },
          url = "http://json.schemastore.org/stylelintrc.json",
        },
      },
    },
  },
}

local servers = { "html", "cssls", "prismals", "pylsp" }
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
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "LineNr", numhl = "" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "LineNr", numhl = "" })
--
-- lspconfig.pyright.setup { blabla}
