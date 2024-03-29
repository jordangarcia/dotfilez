---@type LazyPluginSpec[]
return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("core.utils").lazy_load "nvim-treesitter"
    end,
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
        "yaml",
      },
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = {
        enable = true,
      },
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  -- enables sticky scroll
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
