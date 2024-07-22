---@type LazyPluginSpec[]
return {
  {
    "jordangarcia/ts-actions.nvim",
    dir = "~/code/ts-actions.nvim",
    event = "VeryLazy",
    keys = {

      {
        "<C-n>",
        function()
          require("ts-actions").next()
        end,
        desc = "test",
        mode = "n",
      },
    },
    dependencies = {
      { "MunifTanjim/nui.nvim", lazy = true },
    },

    config = function()
      ---@class CodeAction
      ---@field title string
      ---@field kind? string
      ---@field isPreferred? boolean
      ---@field diagnostics? Diagnostic[]
      ---@field edit? table
      ---@field command? table
      ---@field client_id integer
      ---@field client_name string
      ---@field buffer integer

      local ts_priority_f = {
        { key = "f", pattern = "^update import", order = 102 },
        { key = "f", pattern = "^add import", order = 101 },
        { key = "f", pattern = "^fix this", order = 101 },
        { key = "f", pattern = "^add async modifier", order = 100 },
        { key = "f", pattern = "^change spelling", order = 100 },
        { key = "f", pattern = "^prefix .* with an underscore", order = 100 },
        { key = "f", pattern = "^update the dependencies array", order = 100 },
        { key = "F", pattern = "^fix all", order = 99 },
        { key = "d", pattern = "disable .* for this line", order = 99 },
        { key = "D", pattern = "disable .* entire file", order = 98 },
      }
      local ts_priority = {
        { key = "i", pattern = "^update import", order = 102 },
        { key = "i", pattern = "^add import", order = 101 },
        { key = "f", pattern = "^fix this", order = 101 },
        { key = "F", pattern = "^fix all", order = 100 },
        { key = "s", pattern = "change spelling", order = 100 },
        { key = "u", pattern = "update the dependencies array", order = 100 },
        { key = "d", pattern = "disable .* for this line", order = 99 },
        { key = "D", pattern = "disable .* entire file", order = 98 },
      }
      require("ts-actions").setup {
        ---@class ActionConfig
        ---@field pattern string
        ---@field key string
        ---@field order? integer
        ---@type table<string, ActionConfig[]>
        priority = {
          ["typescript"] = ts_priority_f,
          ["typescriptreact"] = ts_priority_f,
        },
        severity = {
          ["typescriptreact"] = vim.diagnostic.severity.ERROR,
          ["typescript"] = vim.diagnostic.severity.ERROR,
          ["lua"] = vim.diagnostic.severity.WARN,
        },
        ---@param action CodeAction
        filter_function = function(action)
          -- Check if action is not nil
          if not action then
            return false
          end

          -- Check if has isPreferred
          if type(action.isPreferred) == "boolean" and action.isPreferred == false then
            return false
          end

          -- Check if title exists and contains "refactor."
          if type(action.kind) == "string" and action.kind:find "^refactor%." then
            return false
          end

          -- Default to false if none of the conditions are met
          return true
        end,
      }
    end,
  },
}
