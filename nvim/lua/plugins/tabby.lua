-- local action_state = require "telescope.actions.state"
-- local z_utils = require "telescope._extensions.zoxide.utils"

---@type LazyPluginSpec[]
return {
  {
    "nanozuki/tabby.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<C-t>",
        "<CMD> $tabnew <CR>",
        desc = "new tab",
      },
    },
    config = function(self, opts)
      local theme = {
        fill = "TabLineFill",
        -- fill = { fg = "#f2e9de", bg = "#907aa9", style = "italic" },
        head = "TabLine",
        current_tab = "TabLineSel",
        tab = "TabLineOff",
        win = "TabLine",
        tail = "TabLine",
      }
      require("tabby.tabline").set(function(line)
        return {
          -- {
          --   { "  ", hl = theme.head },
          --   line.sep("", theme.head, theme.fill),
          -- },
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
              -- return icon .. " " .. win.buf_name()
            end)
            for i = #wins, 2, -1 do
              table.insert(wins, i, { " | ", hl = sepHl })
            end

            return {
              line.sep("█", hl, theme.fill),
              -- tab.is_current() and "" or "󰆣",
              tab.number(),
              wins,
              -- table.concat(wins, " | "),
              -- tab.name(),
              -- line.sep("█", hl, theme.fill),
              line.sep("▊", hl, theme.fill),
              hl = hl,
              margin = " ",
            }
          end),
          line.spacer(),
          -- line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
          --   return {
          --     line.sep("", theme.win, theme.fill),
          --     win.is_current() and "" or "",
          --     win.buf_name(),
          --     line.sep("", theme.win, theme.fill),
          --     hl = theme.win,
          --     margin = " ",
          --   }
          -- end),
          -- {
          --   line.sep("", theme.tail, theme.fill),
          --   { "  ", hl = theme.tail },
          -- },
          hl = theme.fill,
        }
      end)
    end,
  },
}
