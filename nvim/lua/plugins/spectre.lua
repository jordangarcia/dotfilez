return {
  "nvim-pack/nvim-spectre",
  -- they broke it
  commit = "d20dcf7",
  event = "VeryLazy",
  keys = {
    {
      "<leader>rw",
      function()
        local _, ls, cs = unpack(vim.fn.getpos "v")
        local _, le, ce = unpack(vim.fn.getpos ".")
        local visual = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
        local text = visual[1] or ""
        require("spectre").open_visual { search_text = text }
      end,
      desc = "Find+Replace [w]ord",
      mode = "v",
    },
    {
      "<leader>rf",
      function()
        require("spectre").open_file_search { select_word = true }
      end,
      desc = "Find+Replace [f]ile",
      mode = "n",
    },
    {
      "<leader>rw",
      function()
        require("spectre").open_visual { select_word = true }
      end,
      desc = "Find+Replace [w]ord",
      mode = "n",
    },
    {
      "<leader>ra",
      function()
        require("spectre").toggle()
      end,
      desc = "Find+Replace [a]ll",
      mode = "n",
    },
  },
}
