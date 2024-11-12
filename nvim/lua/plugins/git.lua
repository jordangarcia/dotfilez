---@type LazyPluginSpec[]
return {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>ghr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Git [h]unk [r]eset",
        mode = "n",
      },
      {
        "<leader>ghp",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Git [h]unk [p]review",
        mode = "n",
      },
      {
        "[h",
        function()
          require("gitsigns").prev_hunk()
        end,
        desc = "Prev hunk",
        mode = "n",
      },
      {
        "]h",
        function()
          require("gitsigns").next_hunk()
        end,
        desc = "Next hunk",
        mode = "n",
      },
      { "<leader>gf", "<cmd> Telescope git_bcommits <CR>", "Git [f]ile history (telescope)", mode = "n" },
      { "<leader>gc", "<cmd> Telescope git_commits <CR>", "Git [c]ommits (telescope)", mode = "n" },
      { "<leader>gs", "<cmd> Telescope git_status <CR>", "Git [s]tatus (telescope)", mode = "n" },
      {
        "<leader>gz",
        function()
          require("gitsigns.actions").toggle_signs()
        end,
        desc = "[G]itsigns toggle [z]enmode",
        mode = "n",
      },
      {
        "<leader>gt",
        function()
          require("gitsigns").toggle_deleted()
        end,
        desc = "Git [t]oggle deleted",
        mode = "n",
      },
    },
    ft = { "gitcommit", "diff" },
    init = function()
      -- load gitsigns only when a git file is opened
      vim.api.nvim_create_autocmd({ "BufRead" }, {
        group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
        callback = function()
          vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
          if vim.v.shell_error == 0 then
            vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
            vim.schedule(function()
              require("lazy").load { plugins = { "gitsigns.nvim" } }
            end)
          end
        end,
      })
    end,
    opts = {
      attach_to_untracked = true,
      signcolumn = false,
      signs = {
        -- use basic signs here becuase we dont want multiple characters..
        add = { text = "|" },
        change = { text = "|" },
        delete = { text = ">" },
        topdelete = { text = ">" },
        changedelete = { text = "|" },
        untracked = { text = "|" },
        -- add = { text = "▎" },
        -- change = { text = "▎" },
        -- delete = { text = "" },
        -- topdelete = { text = "" },
        -- changedelete = { text = "▎" },
        -- untracked = { text = "▎" },

        -- add = { text = "│" },
        -- change = { text = "│" },
        -- delete = { text = "│" },
        -- delete = { text = "󰍵│" },
        -- topdelete = { text = "‾" },
        -- changedelete = { text = "~" },
        -- untracked = { text = "│" },
      },
    },
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup(opts)
    end,
  },

  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    keys = {
      { "<leader>gd", "<cmd> Gvdiffsplit <cr>", desc = "Git [d]iff", mode = "n" },
      { "<leader>gb", "<cmd> Git blame <cr>", desc = "Git [b]lame", mode = "n" },
      { "<leader>gg", "<cmd> Git <cr>", desc = "Git git", mode = "n" },
      { "<leader>gl", "<cmd> Gclog <cr>", desc = "Git [l]og", mode = "n" },
      { "<leader>g3", "<cmd> Gvdiffsplit! <cr>", desc = "Git diff [3]way", mode = "n" },
    },
  },
  { "akinsho/git-conflict.nvim", version = "*", config = true },
}
