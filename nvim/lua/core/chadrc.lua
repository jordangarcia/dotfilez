---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "core.highlights"

M.ui = {
  nvdash = {
    load_on_startup = false,
  },
  theme = "kanagawa",
  theme_toggle = { "kanagawa", "one_light" },
  -- lsp_semantic_tokens = true, -- needs nvim v0.9, just adds highlight groups for lsp semantic tokens
  hl_override = highlights.override,
  hl_add = highlights.add,

  cmp = {
    icons = true,
    lspkind_text = true,
    -- style = "default", -- default/flat_light/flat_dark/atom/atom_colored
    style = "flat_dark",
    border_color = "grey_fg", -- only applicable for "default" style, use color names from base30 variables
    selected_item_bg = "colored", -- colored / simple
  },

  statusline = {
    theme = "default", -- default/vscode/vscode_colored/minimal
    separator_style = "block",

    -- default/round/block/arrow (separators work only for "default" statusline theme;
    -- round and block will work for the minimal theme only)
    -- separator_style = "block",
    -- overriden_modules = nil,
    -- modules arg here is the default table of modules
    overriden_modules = require "custom.statusline",
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
