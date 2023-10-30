local overrides = require "custom.configs.overrides"

---@type NvPluginSpec[]
local plugins = {
  {
    "lukas-reineke/indent-blankline.nvim",
    enabled = true,
  },

  -- {
  --   "rebelot/kanagawa.nvim",
  --   lazy = false,
  --   config = function()
  --     vim.cmd "colorscheme kanagawa"
  --   end,
  -- },
  -- Override plugin definition options
  {
    "NvChad/nvim-colorizer.lua",
    opts = require "custom.configs.colorizer",
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          require "custom.configs.null-ls"
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- override plugin configs
  {
    "williamboman/mason.nvim",
    opts = overrides.mason,
  },
  {
    "NvChad/nvterm",
    enabled = false,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = overrides.treesitter,
  },

  {
    "nvim-tree/nvim-tree.lua",
    opts = require "custom.configs.nvimtree",
  },

  {
    "knubie/vim-kitty-navigator",
    lazy = false,
  },
  -- http://vimcasts.org/episodes/fugitive-vim-resolving-merge-conflicts-with-vimdiff/
  {
    "tpope/vim-fugitive",
    lazy = false,
    keys = {
      { "<leader>gd", "<cmd> Gvdiffsplit <cr>", desc = "Git diff" },
      { "<leader>gb", "<cmd> Git blame <cr>", desc = "Git blame" },
      { "<leader>gg", "<cmd> Git <cr>", desc = "Git read" },
      { "<leader>gl", "<cmd> Gclog <cr>", desc = "Git log" },
    },
  },

  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      require("alpha").setup(require("custom/configs/startify").config)
    end,
  },

  {
    "jedrzejboczar/possession.nvim",
    lazy = false,
    config = function()
      require("possession").setup {
        autosave = {
          current = true,
        },
        plugins = {
          delete_hidden_buffers = {
            hooks = {
              "before_load",
              vim.o.sessionoptions:match "buffer" and "before_save",
            },
            force = true, -- or fun(buf): boolean
          },
          delete_buffers = true,
        },
        commands = {
          save = "SSave",
          load = "SLoad",
          delete = "SDelete",
          list = "SList",
        },
      }
    end,
  },

  -- override cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {

      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        config = function(_, opts)
          require("plugins.configs.others").luasnip(opts)
        end,
      },
      -- autopairing of (){}[] etc
      {
        "windwp/nvim-autopairs",
        opts = {
          fast_wrap = {},
          disable_filetype = { "TelescopePrompt", "vim" },
        },
        config = function(_, opts)
          require("nvim-autopairs").setup(opts)

          -- setup cmp for autopairs
          local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },
      -- cmp sources plugins
      {
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "zbirenbaum/copilot-cmp",
      },
    },
    opts = function()
      local opts = require "plugins.configs.cmp"
      local overides = require "custom.configs.cmp"
      vim.tbl_deep_extend("force", opts, overides)
    end,
    config = function(_, opts)
      require("cmp").setup(opts)
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup {
        suggestion = {
          enabled = true,
          auto_trigger = true,
          debounce = 75,
          keymap = {
            -- accept = "<C-l>",
            -- accept = "<C-l>",
            accept = "<Tab>",
            accept_word = false,
            accept_line = false,
            next = "<C-k>",
            prev = "<C-j>",
            dismiss = "<C-e>",
          },
        },
        filetypes = {
          ["*"] = true,
        },
        panel = { enabled = true },
      }
    end,
  },

  {
    "nvim-tree/nvim-web-devicons",
    opts = function()
      return { override = require "nvchad.icons.devicons" }
    end,
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "devicons")
      require("nvim-web-devicons").setup(opts)

      require("custom.winbar").setup()
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    opts = function()
      local opts = require "plugins.configs.telescope"
      local overides = require "custom.configs.telescope"
      return vim.tbl_deep_extend("force", opts, overides)
    end,
  },

  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },

  {
    "smoka7/multicursors.nvim",
    lazy = false,
    dependencies = {
      "smoka7/hydra.nvim",
    },
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    config = require "custom.configs.multicursor",
  },

  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = require "custom.configs.lspsaga",
  },
  -- To make a plugin not be loaded
  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = false
  -- },

  -- All NvChad plugins are lazy-loaded by default
  -- For a plugin to be loaded, you will need to set either `ft`, `cmd`, `keys`, `event`, or set `lazy = false`
  -- If you want a plugin to load on startup, add `lazy = false` to a plugin spec, for example
  -- {
  --   "mg979/vim-visual-multi",
  --   lazy = false,
  -- }
}

return plugins
