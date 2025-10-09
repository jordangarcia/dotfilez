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
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
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
