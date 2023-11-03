---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

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
    style = "flat_dark",
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

  tabufline = {
    lazyload = true,
    overriden_modules = function(modules)
      -- no close tab or switch colorscheme button
      modules[4] = (function()
        return ""
      end)()
    end,
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
