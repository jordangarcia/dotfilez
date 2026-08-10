return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  -- filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "svelte" },
  -- root_markers = { ".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js" },
  root_dir = function(fname)
    local util = require "lspconfig.util"

    -- Find ESLint config root
    local eslint_root = util.root_pattern(".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js")(fname)

    -- Find a competing linter root (biome or oxlint) — a closer one wins over eslint
    local other_root = util.root_pattern("biome.json", "biome.jsonc", ".oxlintrc.json")(fname)

    local debug_msg = string.format(
      "ESLint Debug:\nFile: %s\nESLint: %s\nOther linter: %s",
      fname,
      eslint_root or "NOT FOUND",
      other_root or "NOT FOUND"
    )

    -- If no ESLint config found, don't attach
    if not eslint_root then
      vim.notify(debug_msg .. "\nDecision: No ESLint (no config)", vim.log.levels.INFO)
      return nil
    end

    -- If no competing linter config found, use ESLint
    if not other_root then
      vim.notify(debug_msg .. "\nDecision: Use ESLint (no other linter)", vim.log.levels.INFO)
      return eslint_root
    end

    -- Compare path depths - closer to file wins
    local eslint_depth = #vim.split(eslint_root, "/", { plain = true })
    local other_depth = #vim.split(other_root, "/", { plain = true })

    debug_msg = debug_msg .. string.format("\nESLint depth: %d\nOther depth: %d", eslint_depth, other_depth)

    -- If ESLint is deeper (closer to the file), use ESLint
    if eslint_depth > other_depth then
      vim.notify(debug_msg .. "\nDecision: Use ESLint (closer)", vim.log.levels.INFO)
      return eslint_root
    end

    -- Otherwise the other linter is same level or closer, prefer it
    vim.notify(debug_msg .. "\nDecision: Use other linter (closer/same)", vim.log.levels.INFO)
    return nil
  end,
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
