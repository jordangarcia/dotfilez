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
      python = { "expand_tabs", "ruff_format" },
    },
    formatters = {
      -- Ruff fails to parse files that mix tabs and spaces in indentation.
      -- Convert leading tabs to spaces first so ruff_format always gets a
      -- parseable file and can reindent the rest.
      expand_tabs = {
        format = function(self, ctx, lines, callback)
          local width = vim.bo[ctx.buf].tabstop
          local spaces = string.rep(" ", width)

          local expanded = vim.tbl_map(function(line)
            local indent, rest = line:match "^([ \t]*)(.*)$"
            local fixed = indent:gsub("\t", spaces)
            return fixed .. rest
          end, lines)

          callback(nil, expanded)
        end,
      },
      oxfmt = {
        command = "oxfmt",
        stdin = true,
        args = { "--stdin-filepath", "$FILENAME" },
        -- oxfmt resolves .oxfmtrc.json from its CWD and ignores --stdin-filepath
        -- entirely, so run it from the directory holding the nearest config.
        -- Without this, editing gamma/agent/** from the repo root formats at the
        -- root's printWidth 80 instead of agent's 120.
        cwd = function(self, ctx)
          local found = vim.fs.find(".oxfmtrc.json", { path = ctx.filename, upward = true })[1]
          return found and vim.fs.dirname(found) or nil
        end,
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

      -- Markdown formatters reflow lists/tables too aggressively.
      -- Format it manually with :lua require("conform").format().
      if vim.bo[bufnr].filetype == "markdown" then
        return
      end
      return { timeout_ms = 500, lsp_fallback = true }
    end,
  },
}