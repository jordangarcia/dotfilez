local config = function()
  local api = require "typescript-tools.api"
  require("typescript-tools").setup {
    -- this shouldn't be needed now
    -- root_dir = require("lspconfig.util").root_pattern ".git",
    on_attach = require("plugins.configs.lspconfig").on_attach,
    settings = {
      -- spawn additional tsserver instance to calculate diagnostics on it
      separate_diagnostic_server = true,
      -- "change"|"insert_leave" determine when the client asks the server about diagnostic
      -- publish_diagnostic_on = "insert_leve",
      tsserver_file_preferences = {
        -- autoImportFileExcludePatterns = { "**/dist/**" },
        importModuleSpecifierPreference = "relative",
      },
    },
    handlers = {

      documentFormattingProvider = true,
      documentHighlightProvider = true,
      ["textDocument/publishDiagnostics"] = api.filter_diagnostics { -- Ignore 'This may be converted to an async function' diagnostics.
        --conver to esm
        80001,
        80006,
        -- no implicit any on variable
        7043,
      },

      -- ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      --   severity_sort = true,
      --   virtual_text = false,
      -- }),
    },
  }
end

return config
