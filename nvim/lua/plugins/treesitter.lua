---@type LazyPluginSpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "markdown",
        "markdown_inline",
        "prisma",
        "graphql",
        "python",
        "json",
        "hcl",
        "toml",
        "yaml",
      },
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = {
        enable = false,
      },
    },
    keys = {
      {
        "<leader>td",
        function()
          vim.cmd "TSBufDisable highlight"
          vim.cmd "TSBufDisable indent"
          vim.cmd "TSBufDisable incremental_selection"
          print "Treesitter disabled for buffer"
        end,
        desc = "[T]reesitter [d]isable",
        mode = "n",
      },
      {
        "<leader>te",
        function()
          vim.cmd "TSBufEnable highlight"
          vim.cmd "TSBufEnable indent"
          vim.cmd "TSBufEnable incremental_selection"
          print "Treesitter enabled for buffer"
        end,
        desc = "[T]reesitter [e]nable",
        mode = "n",
      },
    },
    config = function(_, opts)
      -- this is handled in syntax.lua now
      -- dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  --
  {
    "nvim-treesitter/nvim-treesitter-context",
    -- cannot get this to work well
    enabled = false,
    -- keys = {
    --   {
    --     "<leader>us",
    --     "<CMD> TSContextToggle <CR>",
    --     desc = "Toggle [s]ticky scroll",
    --   },
    -- },
    cmd = { "TSContextEnable", "TSContextDisable" and "TSContextToggle" },
  },
}
