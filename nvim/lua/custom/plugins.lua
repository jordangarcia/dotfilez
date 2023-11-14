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
      {
        "pmizio/typescript-tools.nvim",
        -- event = "LspAttach",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = require "custom.configs.typescript-tools",
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

  -- dont enable which key for some things
  {
    "folke/which-key.nvim",
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
      defaults = {
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
      },
    },
    config = function(_, opts)
      local wk = require "which-key"
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
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
    enabled = false,
    lazy = false,
  },

  {
    "numToStr/Navigator.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("Navigator").setup {
        -- Disable navigation when the current mux pane is zoomed in
        disable_on_zoom = true,
      }
    end,
  },

  {
    "rmagatti/auto-session",
    lazy = false,
    opts = require "custom.configs.auto-session",
    init = function(_)
      require("core.utils").load_mappings "autosession"
    end,
    config = function(_, opts)
      require("auto-session").setup(opts)
    end,
  },
  -- http://vimcasts.org/episodes/fugitive-vim-resolving-merge-conflicts-with-vimdiff/
  {
    "tpope/vim-fugitive",
    event = "VeryLazy",
    init = function()
      require("core.utils").load_mappings "fugitive"
    end,
  },

  {
    "goolord/alpha-nvim",
    -- since we autoload sessions this isn't needed
    enabled = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    config = function()
      require("alpha").setup(require("custom/configs/startify").config)
    end,
  },

  -- override cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    keys = { ":", "/" },
    dependencies = {

      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        -- no snippets for nwo
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
          -- local cmp_autopairs = require "nvim-autopairs.completion.cmp"
          -- require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
      },
      -- cmp sources plugins
      {
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-path",
        -- "zbirenbaum/copilot-cmp",
      },
    },
    opts = function()
      local opts = require "plugins.configs.cmp"
      local overides = require "custom.configs.cmp"
      return vim.tbl_deep_extend("force", opts, overides)
    end,
    config = function(_, opts)
      local cmp = require "cmp"
      require("cmp").setup(opts)
      require("cmp").setup.filetype({ "gitcommit" }, {
        enabled = false,
      })
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = vim.tbl_deep_extend("force", cmp.mapping.preset.cmdline(), {
          ["<C-l>"] = {
            c = require("cmp.config.mapping").confirm { select = false },
          },
          ["<C-j>"] = {
            c = function(fallback)
              local cmp = require "cmp"
              if cmp.visible() then
                cmp.select_next_item()
              else
                fallback()
              end
            end,
          },
          ["<C-k>"] = {
            c = function(fallback)
              local cmp = require "cmp"
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end,
          },
        }),
        -- mapping = opts.mapping,
        window = { completion = cmp.config.window.bordered { col_offset = 0 } },
        formatting = { fields = { "abbr" } },
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = vim.tbl_deep_extend("force", cmp.mapping.preset.cmdline(), {
          ["<C-l>"] = {
            c = require("cmp.config.mapping").confirm { select = false },
          },
          ["<C-j>"] = {
            c = function(fallback)
              local cmp = require "cmp"
              if cmp.visible() then
                cmp.select_next_item()
              else
                fallback()
              end
            end,
          },
          ["<C-k>"] = {
            c = function(fallback)
              local cmp = require "cmp"
              if cmp.visible() then
                cmp.select_prev_item()
              else
                fallback()
              end
            end,
          },
        }),
        -- mapping = opts.mapping,
        window = { completion = cmp.config.window.bordered { col_offset = 0 } },
        formatting = { fields = { "abbr" } },
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
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
            accept = "<C-l>",
            accept_word = false,
            accept_line = false,
            next = "<C-k>",
            prev = "<C-j>",
            dismiss = "<C-e>",
          },
        },
        filetypes = {
          lua = true,
          javascript = true,
          python = true,
          typescriptreact = true,
          typescript = true,
          json = true,
          yaml = true,
          html = true,
          css = true,
          ["*"] = false,
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

  require "custom.configs.telescope",

  {
    "tpope/vim-surround",
    event = "VeryLazy",
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
  {
    "mg979/vim-visual-multi",
    event = "VeryLazy",
    init = function()
      vim.cmd [[
    let g:VM_maps = {}
        let g:VM_maps['Find Under']         = '<C-f>'
        let g:VM_maps['Find Subword Under'] = '<C-f>'
      ]]
    end,
  },

  -- this is slow af and i dont use it
  -- {
  --   "nvim-treesitter/nvim-treesitter-textobjects",
  --   event = "VeryLazy",
  --   dependencies = { "nvim-treesitter/nvim-treesitter" },
  --   config = function(_, opts)
  --     local opts = require "custom.configs.treesitter-textobjects"
  --
  --     require("nvim-treesitter.configs").setup(opts)
  --   end,
  -- },
  {
    "windwp/nvim-ts-autotag",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup {
        autotag = {
          enable = true,
          enable_rename = true,
          enable_close = true,
          enable_close_on_slash = false,
        },
      }
    end,
  },

  {
    "numToStr/Comment.nvim",
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    opts = function()
      return {
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      }
    end,
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
    init = function()
      require("core.utils").load_mappings "comment"
    end,
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  require "custom.configs.noice",

  {
    "mbbill/undotree",
    event = "VeryLazy",
    init = function(_)
      require("core.utils").load_mappings "undotree"
    end,
  },

  {
    "nvim-pack/nvim-spectre",
    event = "VeryLazy",
    commit = "d20dcf7",
    init = function(_)
      require("core.utils").load_mappings "spectre"
    end,
  },

  -- {
  --   "pwntester/octo.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-tree/nvim-web-devicons",
  --   },
  --   config = function()
  --     require("octo").setup()
  --   end,
  -- },
}

return plugins
