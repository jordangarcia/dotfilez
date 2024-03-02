dofile(vim.g.base46_cache .. "lsp")
require "nvchad.lsp"
local lspconfig = require "lspconfig"

local M = {}

-- export on_attach & capabilities for custom lspconfigs

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
  has_cmp and cmp_nvim_lsp.default_capabilities() or {},
  {}
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
lspconfig["lua_ls"].setup {
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
          [vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types"] = true,
          [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
        },
        maxPreload = 100000,
        preloadFileSize = 10000,
      },
    },
  },
}

lspconfig["graphql"].setup {
  on_attach = M.on_attach,
  capabilities = capabilities,
  root_dir = require("lspconfig.util").root_pattern "package.json",
}
lspconfig["eslint"].setup {
  on_attach = M.on_attach,
  capabilities = capabilities,
  -- root_dir = require("lspconfig.util").root_pattern ".git",
}
lspconfig["jsonls"].setup {
  on_attach = M.on_attach,
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

-- lspconfig["tsserver"].setup {
--   on_attach = M.on_attach,
--   capabilities = M.capabilities,
--   init_options = {
--     hostInfo = "neovim",
--     preferences = {
--       -- autoImportFileExcludePatterns = { "**/dist/**" },
--       importModuleSpecifierPreference = "relative",
--       format = {
--         typescript = {
--           format = {
--             indentSize = vim.o.shiftwidth,
--             convertTabsToSpaces = vim.o.expandtab,
--             tabSize = vim.o.tabstop,
--           },
--         },
--         javascript = {
--           format = {
--             indentSize = vim.o.shiftwidth,
--             convertTabsToSpaces = vim.o.expandtab,
--             tabSize = vim.o.tabstop,
--           },
--         },
--       },
--       completions = {
--         completeFunctionCalls = true,
--       },
--     },
--   },
--   -- handlers = {
--   --
--   --   documentFormattingProvider = true,
--   --   documentHighlightProvider = true,
--   --   -- ["textDocument/publishDiagnostics"] = api.filter_diagnostics { -- Ignore 'This may be converted to an async function' diagnostics.
--   --   --   --conver to esm
--   --   --   80001,
--   --   --   80006,
--   --   --   -- no implicit any on variable
--   --   --   7043,
--   --   -- },
--   --
--   --   -- ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
--   --   --   severity_sort = true,
--   --   --   virtual_text = false,
--   --   -- }),
--   -- },
-- }

lspconfig["terraformls"].setup {
  -- omit on_attach to allow document formatting provider
  capabilities = capabilities,
}

local servers = { "html", "cssls", "prismals", "ruff_lsp", "pyright" }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = M.on_attach,
    capabilities = capabilities,
  }
end

require("lspconfig.configs").vtsls = require("vtsls").lspconfig -- set default server config, optional but recommended

-- If the lsp setup is taken over by other plugin, it is the same to call the counterpart setup function
require("lspconfig").vtsls.setup {
  on_attach = M.on_attach,
  root_dir = function(startpath)
    -- print("root_dir" .. startpath)
    local makeRootPattern = require("lspconfig.util").root_pattern
    return makeRootPattern ".git"(startpath)

    -- were on the same typescript everywhere woo!
    -- -- regex match against /gamma/packages/client/
    -- local in_client = string.match(startpath, "gamma/packages/client/")
    --
    -- -- for gamma the client version is in the root folder, and the server version is in local node_modules
    -- if in_client ~= nil then
    --   return makeRootPattern ".git"(startpath)
    -- else
    --   return makeRootPattern "package.json"(startpath)
    -- end
  end,

  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      format = {
        indentSize = 2,
        tabSize = 2,
      },
    },
  },
}

vim.diagnostic.config {
  virtual_text = false,
}

-- dont show hints in sidebar
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "LineNr", numhl = "" })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "LineNr", numhl = "" })
--
-- lspconfig.pyright.setup { blabla}

return M
