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
  },
  opts = {
    formatters_by_ft = {
      javascript = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      javascriptreact = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
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