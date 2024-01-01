-- local action_state = require "telescope.actions.state"
-- local z_utils = require "telescope._extensions.zoxide.utils"

local api = vim.api

local function getNvimTreeWidth()
  for _, win in pairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].ft == "NvimTree" then
      return api.nvim_win_get_width(win)
    end
  end
  return 0
end

---@type LazyPluginSpec[]
return {
  {
    "nanozuki/tabby.nvim",
    enabled = true,
    lazy = false,
    -- event = "VeryLazy",
    keys = {
      {
        "<C-t>",
        "<CMD> $tabnew <CR>",
        desc = "New tab",
      },
      {
        "<leader>tq",
        "<CMD> tabc <CR>",
        desc = "Tab [q]uit",
      },
      {
        "<leader>t<S-l>",
        "<CMD> +tabmove <CR>",
        desc = "Tab move right",
      },
      {
        "<leader>t<S-h>",
        "<CMD> -tabmove <CR>",
        desc = "Tab move left",
      },
    },
    config = function(self, opts)
      local theme = {
        fill = "TabLineFill",
      }

      require("tabby.tabline").set(function(line)
        return {
          line.tabs().foreach(function(tab)
            local hl = tab.is_current() and "TabLineSel" or "TabLineOff"
            local iconHl = hl .. "Icon"
            local sepHl = hl .. "Sep"
            local wins = line.wins_in_tab(tab.id).foreach(function(win)
              local buf = win.buf()
              local type = buf.type()
              if type == "help" or type == "nofile" then
                return
              end
              local icon = win.file_icon()

              return {
                { icon, hl = iconHl },
                " ",
                win.buf_name(),
                hl = hl,
              }
            end)
            for i = #wins, 2, -1 do
              table.insert(wins, i, { " | ", hl = sepHl })
            end

            return {
              line.sep("█", hl, "TabLineFill"),
              -- tab.is_current() and "" or "󰆣",
              tab.number(),
              " ",
              wins,
              " ",
              line.sep("▊", hl, "TabLineFill"),
              hl = hl,
              margin = "",
            }
          end),
          line.spacer(),
          hl = "TabLineFill",
        }
      end)
    end,
  },
}
