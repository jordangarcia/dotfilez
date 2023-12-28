return {
  "folke/edgy.nvim",
  lazy = false,
  -- event = "VeryLazy",
  keys = {
    {
      "<leader>ue",
      function()
        require("edgy").toggle()
      end,
      desc = "Edgy Toggle",
    },
    -- stylua: ignore
    { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
  },
  opts = function()
    local opts = {
      animate = {
        enabled = false,
      },
      bottom = {
        {
          ft = "toggleterm",
          size = { height = 0.4 },
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        {
          ft = "noice",
          size = { height = 0.4 },
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        {
          ft = "lazyterm",
          title = "LazyTerm",
          size = { height = 0.4 },
          filter = function(buf)
            return not vim.b[buf].lazyterm_cmd
          end,
        },
        "Trouble",
        {
          ft = "trouble",
          filter = function(buf, win)
            return vim.api.nvim_win_get_config(win).relative == ""
          end,
        },
        { ft = "qf", title = "QuickFix" },
        {
          ft = "markdown",
          size = { height = 25 },
          -- don't open help files in edgy that we're editing
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
        {
          ft = "help",
          size = { height = 25 },
          -- don't open help files in edgy that we're editing
          filter = function(buf)
            return vim.bo[buf].buftype == "help"
          end,
        },
        { title = "Spectre", ft = "spectre_panel", size = { height = 0.4 } },
        { title = "Neotest Output", ft = "neotest-output-panel", size = { height = 15 } },
      },
      left = {
        -- {
        --   title = "Neo-Tree",
        --   ft = "neo-tree",
        --   filter = function(buf)
        --     return vim.b[buf].neo_tree_source == "filesystem"
        --   end,
        --   pinned = true,
        --   open = function()
        --     vim.api.nvim_input "<esc><space>e"
        --   end,
        --   -- size = { height = 0.5 },
        -- },

        -- {
        --   ft = "NvimTree",
        --   -- filter = function(buf)
        --   --   return vim.b[buf].neo_tree_source == "filesystem"
        --   -- end,
        --   pinned = true,
        --   open = function()
        --     vim.api.nvim_input "<esc><c-e>"
        --   end,
        --   -- size = { height = 0.5 },
        -- },
        { title = "Neotest Summary", ft = "neotest-summary" },
        -- {
        --   title = "Neo-Tree Git",
        --   ft = "neo-tree",
        --   filter = function(buf)
        --     return vim.b[buf].neo_tree_source == "git_status"
        --   end,
        --   pinned = true,
        --   open = "Neotree position=right git_status",
        -- },
        -- {
        --   title = "Neo-Tree Buffers",
        --   ft = "neo-tree",
        --   filter = function(buf)
        --     return vim.b[buf].neo_tree_source == "buffers"
        --   end,
        --   pinned = true,
        --   open = "Neotree position=top buffers",
        -- },
        -- "neo-tree",
      },
      keys = {
        -- increase width
        ["<c-Right>"] = function(win)
          win:resize("width", 12)
        end,
        -- decrease width
        ["<c-Left>"] = function(win)
          win:resize("width", -12)
        end,
        -- increase height
        ["<c-Up>"] = function(win)
          win:resize("height", 6)
        end,
        -- decrease height
        ["<c-Down>"] = function(win)
          win:resize("height", -6)
        end,
      },
    }
    return opts
  end,
}
