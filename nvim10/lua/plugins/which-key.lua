return {
  "folke/which-key.nvim",
  keys = {
    "<leader>",
    "<c-r>",
    "<c-w>",
    '"',
    "'",
    "`",
    "c",
    "v",
    "g",
    {
      "<leader>?",
      function()
        vim.cmd "WhichKey"
      end,
      desc = "Which-key all keymaps",
      mode = "n",
    },
  },
  event = "VeryLazy",
  opts = {
    presets = {
      operators = false, -- adds help for operators like d, y, ...
      motions = false, -- adds help for motions
      text_objects = true, -- help for text objects triggered after entering an operator
      windows = true, -- default bindings on <c-w>
      nav = true, -- misc bindings to work with windows
    },
    plugins = { spelling = true },
  },
  config = function(_, opts)
    -- dont load colorscheme
    -- dofile(vim.g.base46_cache .. "whichkey")

    local wk = require "which-key"
    wk.setup(opts)
    wk.add {
      mode = { "n", "v" },
      { "<leader><tab>", group = "tabs" },
      { "<leader>b", group = "buffer" },
      { "<leader>e", group = "tree" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>h", group = "harpoon" },
      { "<leader>l", group = "lsp" },
      { "<leader>r", group = "replace" },
      { "<leader>s", group = "session" },
      { "<leader>w", group = "windows" },
      { "<leader>t", group = "tab+treesitter" },
      { "<leader>u", group = "history" },
      { "<leader>x", group = "windows" },
      { "<leader>y", group = "yank" },
      { "[", group = "prev" },
      { "]", group = "next" },
    }
  end,
}
