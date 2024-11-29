return {
  "folke/noice.nvim",

  event = "VeryLazy",
  enabled = true,

  opts = {
    -- you can enable a preset for easier configuration
    presets = {
      -- bottom_search = true, -- use a classic bottom cmdline for search
      command_palette = true, -- position the cmdline and popupmenu together
      long_message_to_split = true, -- long messages will be sent to a split
      -- lsp_doc_border = true, -- add a border to hover docs and signature help
      inc_rename = true,
    },
    -- messages = {
    --   -- NOTE: If you enable messages, then the cmdline is enabled automatically.
    --   -- This is a current Neovim limitation.
    --   -- enabled = false, -- enables the Noice messages UI
    --   view = "notify", -- default view for messages
    --   view_error = "notify", -- view for errors
    --   view_warn = "notify", -- view for warnings
    --   view_history = "messages", -- view for :messages
    --   view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
    -- },
    routes = {
      {
        filter = {
          event = "msg_show",
          kind = "emsg",
          find = "Pattern not found",
        },
        view = "mini",
        -- opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "written",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "^/",
        },
        opts = { skip = true },
      },

      {
        filter = {
          event = "notify",
          kind = "warn",
          find = "lualine",
        },
        opts = { skip = true },
      },

      {
        filter = {
          event = "notify",
          kind = "info",
          find = "No information available",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          kind = "info",
          find = "NvimTree",
        },
        view = "mini",
      },
      {
        filter = {
          event = "notify",
          -- kind = "echo",
          find = "Format request failed",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
          },
        },
        view = "mini",
      },
    },

    lsp = {
      -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
        ["vim.lsp.util.stylize_markdown"] = false,
        ["cmp.entry.get_documentation"] = false,
      },
      hover = {
        enabled = false,
      },
      documentation = {
        enabled = false,
      },
      signature = {
        enabled = false,
      },
      -- progress = {
      --   enabled = false,
      -- },
    },
    views = {
      -- mini = {
      --   position = {
      --     row = "99%",
      --     col = "50%",
      --   },
      --   size = {
      --     width = 60,
      --     height = 1,
      --   },
      --   -- win_options = {
      --   --   winhighlight = { Normal = "Normal" },
      --   -- },
      -- },

      -- cmdline = {
      --   position = {
      --     row = 7,
      --     col = "50%",
      --   },
      --   size = {
      --     width = 60,
      --     height = "auto",
      --   },
      -- },
      cmdline_popup = {
        position = {
          row = 7,
          col = "50%",
        },
        size = {
          width = 100,
          height = "auto",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = 10,
          col = "50%",
        },
        size = {
          width = 60,
          height = 10,
        },
        border = {
          style = "rounded",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
        },
      },
    },
    -- add any options here
  },
  dependencies = {
    -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
    "MunifTanjim/nui.nvim",
    -- OPTIONAL:
    --   `nvim-notify` is only needed, if you want to use the notification view.
    --   If not available, we use `mini` as the fallback
    {
      "rcarriga/nvim-notify",
      opts = {
        background_colour = "#2E3440",
        stages = "static",
        timeout = 1500,
        render = "minimal",
      },
    },
  },
}
