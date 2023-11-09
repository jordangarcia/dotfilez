return {
  "folke/noice.nvim",

  event = "VeryLazy",

  opts = {
    presets = {
      -- bottom_search = true,
    },
    messages = {
      -- NOTE: If you enable messages, then the cmdline is enabled automatically.
      -- This is a current Neovim limitation.
      -- enabled = false, -- enables the Noice messages UI
      view = "notify", -- default view for messages
      view_error = "notify", -- view for errors
      view_warn = "notify", -- view for warnings
      view_history = "messages", -- view for :messages
      view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
    },
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
          event = "notify",
          -- kind = "echo",
          find = "Format request failed",
        },
        opts = { skip = true },
      },
    },

    lsp = {
      progress = {
        enabled = false,
      },
    },
    views = {
      mini = {
        position = {
          row = "99%",
          col = "50%",
        },
        size = {
          width = 60,
          height = 1,
        },
        -- win_options = {
        --   winhighlight = { Normal = "Normal" },
        -- },
      },
      cmdline_popup = {
        position = {
          row = 10,
          col = "50%",
        },
        size = {
          width = 60,
          height = "auto",
        },
      },
      popupmenu = {
        relative = "editor",
        position = {
          row = 13,
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
        timeout = 3000,
        render = "minimal",
      },
    },
  },
}
