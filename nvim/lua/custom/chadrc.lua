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
      local function stbufnr()
        return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
      end
      modules[2] = (function()
        return ""
      end)()
      modules[7] = (function()
        if not rawget(vim, "lsp") then
          return ""
        end

        local errors = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.ERROR })
        local warnings = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.WARN })

        errors = (errors and errors > 0) and ("%#St_lspError#" .. " " .. errors .. " ") or ""
        warnings = (warnings and warnings > 0) and ("%#St_lspWarning#" .. "  " .. warnings .. " ") or ""

        return errors .. warnings
      end)()

      modules[8] = (function()
        local clients = {}
        if rawget(vim, "lsp") then
          for _, client in ipairs(vim.lsp.get_active_clients()) do
            if client.attached_buffers[stbufnr()] and client.name ~= "null-ls" then
              table.insert(clients, client.name)
            end
          end
          local str = table.concat(clients, " ")
          return (vim.o.columns > 100 and "%#St_LspStatus#" .. "   " .. str .. " ")
        end
      end)()

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
