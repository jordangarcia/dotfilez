local utils = require "core.utils"

local config = function()
  require("typescript-tools").setup {
    on_attach = require("plugins.configs.lspconfig").on_attach,
    settings = {
      -- spawn additional tsserver instance to calculate diagnostics on it
      separate_diagnostic_server = false,
      -- "change"|"insert_leave" determine when the client asks the server about diagnostic
      publish_diagnostic_on = "change",
    },
    handlers = {
      documentFormattingProvider = true,
      documentHighlightProvider = true,
      -- ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      --   severity_sort = true,
      --   virtual_text = false,
      -- }),
    },
  }
end

return config