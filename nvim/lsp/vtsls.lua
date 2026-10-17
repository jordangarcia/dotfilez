local tsgo_paths = require "lsp_tsgo_paths"

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

    -- tsgo owns these projects outright. Returning without on_dir keeps vtsls off.
    local is_tsgo_project = tsgo_paths.root_for(bufname) ~= nil
    if is_tsgo_project then
      return
    end

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
