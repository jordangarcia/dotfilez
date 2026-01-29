local tsgo_paths = require "lsp_tsgo_paths"

local function is_tsgo_project(bufname)
  for _, path in ipairs(tsgo_paths) do
    if bufname:find(path, 1, true) then
      return path
    end
  end
  return nil
end

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
    local tsgo_root = is_tsgo_project(bufname)
    if tsgo_root then
      on_dir(tsgo_root)
    end
  end,
}
