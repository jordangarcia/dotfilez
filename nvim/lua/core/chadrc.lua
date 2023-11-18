---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "core.highlights"

-- tabufline
-- #16161D - bg
-- #17171E - inactive bg
-- #1C1C24 - semiactive bg
-- #1F1F28 - active bg
-- #D8616B - icon
-- #4C4C55 - inactive text
-- #C8C3A6 - active text
M.ui = {
  nvdash = {
    load_on_startup = false,
  },
  theme = "kanagawa",
  theme_toggle = { "kanagawa", "one_light" },
  -- lsp_semantic_tokens = true, -- needs nvim v0.9, just adds highlight groups for lsp semantic tokens
  hl_override = highlights.override,
  hl_add = highlights.add,
  transparency = true,

  cmp = {
    icons = true,
    lspkind_text = true,
    -- style = "default", -- default/flat_light/flat_dark/atom/atom_colored
    style = "flat_dark",
    border_color = "grey_fg", -- only applicable for "default" style, use color names from base30 variables
    selected_item_bg = "colored", -- colored / simple
  },

  statusline = {
    theme = "minimal", -- default/vscode/vscode_colored/minimal
    separator_style = "block",

    -- there is no way to disable statusline, so just render nothing
    overriden_modules = function(modules)
      for i = 1, 11, 1 do
        modules[i] = (function()
          return ""
        end)()
      end
    end,
  },

  telescope = { style = "borderless" }, -- borderless / bordered

  tabufline = {
    enabled = true,
    lazyload = true,
    overriden_modules = function(modules)
      -- no close tab or switch colorscheme button
      modules[4] = (function()
        return ""
      end)()
    end,
  },

  lsp = {
    -- show function signatures i.e args as you type
    signature = {
      disabled = false,
      silent = true, -- silences 'no signature help available' message from appearing
    },
  },
}

M.plugins = {}

-- check core.mappings for table structure
M.mappings = {}

return M
