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
        "hcl",
        "toml",
        "yaml",
        "terraform",
      },
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = {
        enable = true,
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
      dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    enabled = false,
    config = function()
      require("nvim-treesitter.configs").setup {
        textobjects = {
          select = {
            enable = true,

            -- Automatically jump forward to textobj, similar to targets.vim
            lookahead = true,

            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              -- You can optionally set descriptions to the mappings (used in the desc parameter of
              -- nvim_buf_set_keymap) which plugins like which-key display
              ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
              -- You can also use captures from other query groups like `locals.scm`
              ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
            },
            -- You can choose the select mode (default is charwise 'v')
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * method: eg 'v' or 'o'
            -- and should return the mode ('v', 'V', or '<c-v>') or a table
            -- mapping query_strings to modes.
            selection_modes = {
              ["@parameter.outer"] = "v", -- charwise
              ["@function.outer"] = "V", -- linewise
              ["@class.outer"] = "<c-v>", -- blockwise
            },
            -- If you set this to `true` (default is `false`) then any textobject is
            -- extended to include preceding or succeeding whitespace. Succeeding
            -- whitespace has priority in order to act similarly to eg the built-in
            -- `ap`.
            --
            -- Can also be a function which gets passed a table with the keys
            -- * query_string: eg '@function.inner'
            -- * selection_mode: eg 'v'
            -- and should return true or false
            include_surrounding_whitespace = true,
          },
        },
      }
    end,
  },
  -- enables sticky scroll
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
