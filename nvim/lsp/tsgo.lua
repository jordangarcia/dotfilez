local tsgo_paths = require "lsp_tsgo_paths"

return {
  cmd = { "tsgo", "--lsp", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_dir = function(bufnr, on_dir)
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    local tsgo_root = tsgo_paths.root_for(bufname)
    if tsgo_root then
      on_dir(tsgo_root)
    end
  end,
}
