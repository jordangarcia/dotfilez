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
lspconfig["lua_ls"].setup {
  on_attach = M.on_attach,
  capabilities = M.capabilities,

  settings = {
    Lua = {
      workspace = {
        library = {
          -- string.format("%s/.hammerspoon/Spoons/EmmyLua.spoon/annotations", os.getenv "HOME"),
        },
      },
      runtime = {
        -- Tell the language server which version of Lua you're using
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
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

lspconfig["terraformls"].setup {
  -- omit on_attach to allow document formatting provider
  capabilities = capabilities,
}

-- setup python
lspconfig["pyright"].setup {
  on_attach = M.on_attach_no_formatting,
  capabilities = capabilities,
}

lspconfig["ruff"].setup {
  -- dont setup on_attach becuase it disables the formatting provider
  capabilities = capabilities,
}

-- Native LSP servers (configured via lsp/*.lua files)
vim.lsp.enable({ 'html', 'cssls', 'taplo' })

-- Keep prismals in lspconfig for now
lspconfig["prismals"].setup {
  -- allow prettier
  on_attach = M.on_attach,
  capabilities = capabilities,
}

require("lspconfig.configs").vtsls = require("vtsls").lspconfig -- set default server config, optional but recommended

-- If the lsp setup is taken over by other plugin, it is the same to call the counterpart setup function
lspconfig["vtsls"].setup {
  -- allow prettier
  on_attach = M.on_attach_no_formatting,
  root_dir = function(startpath)
    -- print("root_dir" .. startpath)
    local makeRootPattern = require("lspconfig.util").root_pattern

    -- were on the same typescript everywhere woo!
    -- -- regex match against /gamma/packages/client/
    local in_requestnow = string.match(startpath, "requestnow/ui")

    --
    -- -- for gamma the client version is in the root folder, and the server version is in local node_modules
    if in_requestnow ~= nil then
      return makeRootPattern "package.json"(startpath)
    end
    --   return makeRootPattern "package.json"(startpath)
    -- end
    return makeRootPattern ".git"(startpath)
  end,

  settings = {
    typescript = {
      tsserver = {
        -- log = "normal",
        maxTsServerMemory = 8192,
      },
    },
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
