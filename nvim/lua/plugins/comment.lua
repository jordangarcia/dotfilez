---@type LazyPluginSpec
return {
  "numToStr/Comment.nvim",
  dependencies = {
    "JoosepAlviste/nvim-ts-context-commentstring",
  },
  keys = {
    { "gcc", mode = "n", desc = "Comment toggle current line" },
    { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
    { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
    { "gbc", mode = "n", desc = "Comment toggle current block" },
    { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
    { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    {
      "<C-/>",
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      desc = "Toggle comment",
      mode = "n",
    },
    {
      "<C-/>",
      function()
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end,
      desc = "Toggle comment",
      mode = "v",
    },
  },

  opts = function()
    return {
      pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
    }
  end,
  config = function(_, opts)
    require("Comment").setup(opts)
  end,
}
