return function(modules)
  local function stbufnr()
    return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  end

  local sep = { left = "█", right = "█" }
  local fn = vim.fn
  -- better CWD
  modules[1] = (function()
    local path = require("custom.path_utils").normalize_to_home(fn.getcwd())
    local dir_icon = "%#St_cwd_icon#" .. "󰉋 "
    local dir_name = "%#St_cwd_text#" .. " " .. path .. " "
    return "%#St_cwd_sep#" .. sep.left .. dir_icon .. dir_name .. "%#St_file_sep#"
  end)()

  -- dont show filename down here
  modules[2] = (function()
    return ""
  end)()

  -- only show errors + warnings
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
  -- show all lsps
  modules[8] = (function()
    local status, result = pcall(function(...)
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
    end)
    if not status then
      return ""
    end
    return result
  end)()

  -- dont show cwd here
  modules[9] = (function()
    return ""
  end)()
  -- show line numbers + pct
  modules[10] = (function()
    local left_sep = "%#St_pos_sep#" .. sep.left .. "%#St_pos_icon#" .. " "

    local current_line = fn.line(".", vim.g.statusline_winid)
    local total_line = fn.line("$", vim.g.statusline_winid)
    local text = math.modf((current_line / total_line) * 100) .. tostring "%%"
    text = string.format("%4s", text)

    text = (current_line == 1 and "Top") or text
    text = (current_line == total_line and "Bot") or text

    return left_sep .. "%#St_pos_text#" .. " " .. current_line .. " | " .. text .. " "
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
end
