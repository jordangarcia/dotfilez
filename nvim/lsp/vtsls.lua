local tsgo_paths = require "lsp_tsgo_paths"

local function is_tsgo_project(bufname)
  for _, path in ipairs(tsgo_paths) do
    if bufname:find(path, 1, true) then
      return true
    end
  end
  return false
end

return {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "vue",
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_dir = function(bufnr, on_dir)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" }
    local root = vim.fs.find(root_markers, {
      upward = true,
      stop = vim.env.HOME,
      path = vim.fs.dirname(bufname),
    })[1]

    if root then
      on_dir(vim.fs.dirname(root))
    end
  end,
  on_attach = function(client, bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    -- In tsgo projects, disable everything except code actions
    if is_tsgo_project(bufname) then
      client.server_capabilities.completionProvider = nil
      client.server_capabilities.hoverProvider = nil
      client.server_capabilities.signatureHelpProvider = nil
      client.server_capabilities.definitionProvider = nil
      client.server_capabilities.typeDefinitionProvider = nil
      client.server_capabilities.implementationProvider = nil
      client.server_capabilities.referencesProvider = nil
      client.server_capabilities.documentHighlightProvider = nil
      client.server_capabilities.documentSymbolProvider = nil
      client.server_capabilities.workspaceSymbolProvider = nil
      client.server_capabilities.renameProvider = nil
      client.server_capabilities.documentFormattingProvider = nil
      client.server_capabilities.documentRangeFormattingProvider = nil
      client.server_capabilities.semanticTokensProvider = nil
      client.server_capabilities.inlayHintProvider = nil
      -- Keep codeActionProvider for removeUnusedImports etc.

      -- Disable diagnostics from vtsls
      client.handlers["textDocument/publishDiagnostics"] = function() end
    end
  end,
  settings = {
    typescript = {
      tsdk = vim.fn.expand "~/code/gamma/node_modules/typescript/lib",
      tsserver = {
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
