-- this isn't currently being used because of chad tabline being good
---@type LazyPluginSpec[]
return {
  -- This is what powers LazyVim's fancy-looking
  -- tabs, which include filetype icons and close buttons.
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>",          desc = "Delete other buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>",           desc = "Delete buffers to the right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",            desc = "Delete buffers to the left" },
      { "<S-h>",      "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer" },
      { "<S-l>",      "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer" },
      { "[b",         "<cmd>BufferLineCyclePrev<cr>",            desc = "Prev buffer" },
      { "]b",         "<cmd>BufferLineCycleNext<cr>",            desc = "Next buffer" },
    },
    opts = {

      options = {
        numbers = "ordinal",

        close_command = function(n)
          require("mini.bufremove").delete(n, false)
        end,
        right_mouse_command = function(n)
          require("mini.bufremove").delete(n, false)
        end,
        always_show_bufferline = true,
        offsets = {
          {
            filetype = "NvimTree",
            text = "",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },

      highlights = {
        fill = {
          bg = require("core.highlights").palette.sumiInk0,
        },
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd("BufAdd", {
        callback = function()
          vim.schedule(function()
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },
  {
    "echasnovski/mini.bufremove",
    event = "VeryLazy",
    keys = {
      {
        "<leader>bd",
        function()
          require("custom.buffer_utils").smart_close_buffer()
        end,
        desc = "Delete Buffer",
      },
      -- stylua: ignore
      { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
    },
  },
  {
    "backdround/tabscope.nvim",
    lazy = true,
    event = "VeryLazy",
    config = function()
      -- todo this needs to go somewhere else
      vim.api.nvim_set_hl(0, "TblineFill", { bg = "#16161D" })
      vim.api.nvim_set_hl(0, "TbLineBufOn", { bg = "#1F1F28", fg = "#C8C3A6", italic = true, bold = true })
      vim.api.nvim_set_hl(0, "TbLineBufOn", { bg = "#1F1F28", fg = "#C8C3A6", italic = true, bold = true })
      vim.api.nvim_set_hl(0, "TbLineBufOff", { bg = "#17171e", fg = "#4c4c55" })
      vim.api.nvim_set_hl(0, "TbLineBufOffClose", { link = "TbLineBufOff" })
      -- vim.api.nvim_set_hl(0, "TblineFill", { bg = "#16161D" })
      -- vim.cmd [[ hl TblineFill guibg=#16161D ]]
      -- TblineFill = { bg = palette.sumiInk0 },
      -- TbLineFill = { bg = palette.sumiInk0 },
      -- TabLine = { bg = palette.sumiInk0 },
      -- TblineBufOn = { bg = palette.sumiInk3, fg = palette.fujiWhite },
    end,
  },
}
