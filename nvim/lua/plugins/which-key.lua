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
    wk.register {
      mode = { "n", "v" },
      ["]"] = { name = "+next" },
      ["["] = { name = "+prev" },
      ["<leader><tab>"] = { name = "+tabs" },
      ["<leader>b"] = { name = "+buffer" },
      ["<leader>e"] = { name = "+tree" },
      ["<leader>f"] = { name = "+find" },
      ["<leader>g"] = { name = "+git" },
      ["<leader>gh"] = { name = "+hunks" },
      ["<leader>h"] = { name = "+harpoon" },
      ["<leader>l"] = { name = "+lsp" },
      ["<leader>r"] = { name = "+replace" },
      ["<leader>s"] = { name = "+session" },
      ["<leader>w"] = { name = "+windows" },
      ["<leader>y"] = { name = "+yank" },
    }
  end,
}
