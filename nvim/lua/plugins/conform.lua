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
      javascript = { "oxfmt", "biome", "prettier", stop_after_first = true },
      typescript = { "oxfmt", "biome", "prettier", stop_after_first = true },
      typescriptreact = { "oxfmt", "biome", "prettier", stop_after_first = true },
      javascriptreact = { "oxfmt", "biome", "prettier", stop_after_first = true },
      css = { "oxfmt", "biome", "prettier", stop_after_first = true },
      json = { "oxfmt", "biome", "prettier", stop_after_first = true },
      jsonc = { "oxfmt", "biome", "prettier", stop_after_first = true },
      scss = { "oxfmt", "prettier", stop_after_first = true },
      html = { "oxfmt", "prettier", stop_after_first = true },
      yaml = { "oxfmt", "prettier", stop_after_first = true },
      markdown = { "oxfmt", "prettier", stop_after_first = true },
      graphql = { "oxfmt", "prettier", stop_after_first = true },
      lua = { "stylua" },
      python = { "ruff_format" },
    },
    formatters = {
      oxfmt = {
        command = "oxfmt",
        stdin = true,
        args = { "--stdin-filepath", "$FILENAME" },
        condition = function(self, ctx)
          return vim.fs.find(".oxfmtrc.json", { path = ctx.filename, upward = true })[1] ~= nil
        end,
      },
      biome = {
        condition = function(self, ctx)
          return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1] ~= nil
        end,
      },
    },
    format_on_save = function(bufnr)
      if vim.b[bufnr].disable_format_on_save then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
  },
}