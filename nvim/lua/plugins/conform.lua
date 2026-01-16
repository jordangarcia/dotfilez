---@type LazyPluginSpec
return {
  "stevearc/conform.nvim",
  lazy = true,
  event = "BufWritePre",
  keys = {
    {
      "<leader>tf",
      function()
        -- check if disable_format_on_save is set
        if vim.b.disable_format_on_save then
          vim.b.disable_format_on_save = nil
          vim.notify "format_on_save: enabled"
        else
          vim.b.disable_format_on_save = true
          vim.notify "format_on_save: disabled"
        end
      end,
      desc = "Toggle format on save",
    },
    {
      "<leader>uc",
      "<cmd>ConformInfo<cr>",
      desc = "Open conform info",
    },
  },
  opts = {
    formatters_by_ft = {
      -- Biome will be used if biome.json exists, otherwise fallback to prettier
      javascript = { "biome", "prettier", stop_after_first = true },
      typescript = { "biome", "prettier", stop_after_first = true },
      typescriptreact = { "biome", "prettier", stop_after_first = true },
      javascriptreact = { "biome", "prettier", stop_after_first = true },
      css = { "biome", "prettier", stop_after_first = true },
      json = { "biome", "prettier", stop_after_first = true },
      jsonc = { "biome", "prettier", stop_after_first = true },
      scss = { "prettier" },
      html = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      graphql = { "prettier" },
      lua = { "stylua" },
      python = { "ruff_format" },
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].disable_format_on_save then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
  },
}