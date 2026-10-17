return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  -- root_dir lives in lua/plugins/lsp.lua. Neovim merges lsp/*.lua in runtimepath
  -- order and the last file wins, so nvim-lspconfig would override anything set here.
  -- filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  -- root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js" },
  settings = {
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = {
        enable = true,
      },
    },
    codeActionOnSave = {
      enable = true,
      mode = "all",
    },
    format = true,
    nodePath = "",
    onIgnoredFiles = "off",
    packageManager = "npm",
    quiet = true,
    -- rulesCustomizations = {
    --   { rule = "prettier/*", severity = "off" }
    -- },
    run = "onType",
    useESLintClass = false,
    validate = "on",
    workingDirectory = {
      mode = "location",
    },
  },
}
