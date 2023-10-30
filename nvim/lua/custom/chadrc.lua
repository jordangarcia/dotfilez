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

  statusline = {
    theme = "default", -- default/vscode/vscode_colored/minimal
    separator_style = "block",

    -- default/round/block/arrow (separators work only for "default" statusline theme;
    -- round and block will work for the minimal theme only)
    -- separator_style = "block",
    -- overriden_modules = nil,
    -- modules arg here is the default table of modules
    overriden_modules = function(modules)

      -- TODO make paste configurable
      -- table.insert(
      --   modules,
      --   11,
      --   (function()
      --     local icon = " "
      --     local left_sep = "%#St_paste_sep#" .. "█" .. "%#St_paste_icon#" .. icon
      --     local val = vim.api.nvim_get_option('clipboard')
      --     local text = val == 'unnamedplus' and 'on' or 'off'
      --     -- if val== 'unnamedplus' then
      --     --   text = 'on'
      --     -- end
      --     -- local text =  vim.o.cliboard == 'unnamedplus' and 'on' or "off"
      --
      --     -- return left_sep .. "%#St_paste_text#" .. " " .. text .. " "
      --     return left_sep .. "%#St_paste_text#" .. " " .. text .. " "
      --   end)()
      -- )
    end,
  },

  tabufline = {
    lazyload = true,
    overriden_modules = nil,
  },
}

M.plugins = "custom.plugins"

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

return M
