-- @Data
local plugins = {
  "nvim-lua/plenary.nvim",

  "rebelot/kanagawa.nvim",

  -- {
  --   "NvChad/base46",
  --   branch = "v2.0",
  --   build = function()
  --     require("base46").load_all_highlights()
  --   end,
  -- },

  -- {
  -- 	"NvChad/ui",
  -- 	branch = "v2.0",
  -- 	lazy = false,
  -- },

  -- {
  --   "NvChad/nvterm",
  --   init = function()
  --     require("utils").load_mappings "nvterm"
  --   end,
  --   config = function(_, opts)
  --     require "base46.term"
  --     require("nvterm").setup(opts)
  --   end,
  -- },

  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   init = function()
  --     require("utils").lazy_load "nvim-colorizer.lua"
  --   end,
  --   config = function(_, opts)
  --     require("colorizer").setup(opts)
  --
  --     -- execute colorizer as soon as possible
  --     vim.defer_fn(function()
  --       require("colorizer").attach_to_buffer(0)
  --     end, 0)
  --   end,
  -- },

  {
    "nvim-tree/nvim-web-devicons",
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "devicons")
      require("nvim-web-devicons").setup(opts)
    end,
  },

  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   version = "2.20.7",
  --   init = function()
  --     require("utils").lazy_load "indent-blankline.nvim"
  --   end,
  --   opts = function()
  --     return require("plugins.configs.others").blankline
  --   end,
  --   config = function(_, opts)
  --     require("utils").load_mappings "blankline"
  --     dofile(vim.g.base46_cache .. "blankline")
  --     require("indent_blankline").setup(opts)
  --   end,
  -- },

  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("utils").lazy_load "nvim-treesitter"
    end,
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = function()
      return require "plugins.configs.treesitter"
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "syntax")
      require("nvim-treesitter.configs").setup(opts)
      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
      parser_config.tsx.filetype_to_parsername = { "javascript", "typescript.tsx" }
    end,
  },

  -- git stuff
  {
    "lewis6991/gitsigns.nvim",
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
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "git")
      require("gitsigns").setup {
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "󰍵" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "│" },
        },
        on_attach = function() end,
      }
    end,
  },

  {
    "dinhhuy258/git.nvim",

    -- init = function()
    --   init = function()
    --     require("utils").load_mappings "comment"
    --   end,
    -- },

    init = function()
      --     require("utils").load_mappings "comment"
      -- load gitsigns only when a git file is opened
      vim.api.nvim_create_autocmd({ "BufRead" }, {
        group = vim.api.nvim_create_augroup("GitLazyLoad", { clear = true }),
        callback = function()
          vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
          if vim.v.shell_error == 0 then
            vim.api.nvim_del_augroup_by_name "GitLazyLoad"
            vim.schedule(function()
              require("lazy").load { plugins = { "git.nvim" } }
            end)
          end
        end,
      })
    end,
    opts = function() end,
    config = function(_, opts)
      require("git").setup {
        default_mappings = true, -- NOTE: `quit_blame` and `blame_commit` are still merged to the keymaps even if `default_mappings = false`

        keymaps = {
          -- Open blame window
          blame = "<Leader>gb",
          -- Close blame window
          quit_blame = "q",
          -- Open blame commit
          blame_commit = "<CR>",
          -- Open file/folder in git repository
          browse = "<Leader>go",
          -- Open pull request of the current branch
          -- open_pull_request = "<Leader>gp",
          -- Create a pull request with the target branch is set in the `target_branch` option
          -- create_pull_request = "<Leader>gn",
          -- Opens a new diff that compares against the current index
          diff = "<Leader>gd",
          -- Close git diff
          diff_close = "<Leader>gD",
          -- Revert to the specific commit
          revert = "<Leader>gr",
          -- Revert the current file to the specific commit
          revert_file = "<Leader>gR",
        },
        -- Default target branch when create a pull request
        target_branch = "main",
        -- Private gitlab hosts, if you use a private gitlab, put your private gitlab host here
        -- private_gitlabs = { "https://xxx.git.com" },
        -- Enable winbar in all windows created by this plugin
        winbar = false,
      }
    end,
  },

  -- lsp stuff
  {

    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = function()
      return {
        ensure_installed = {
          -- lua stuff
          "lua-language-server",
          "stylua",

          -- web dev stuff
          "css-lsp",
          "html-lsp",
          "typescript-language-server",
          "prettier",
          "prettierd",
          "eslint_d",
          "prisma-language-server",
          "graphql-language-service-cli",
        },

        PATH = "skip",

        ui = {
          icons = {
            package_pending = " ",
            package_installed = "󰄳 ",
            package_uninstalled = " 󰚌",
          },

          keymaps = {
            toggle_server_expand = "<CR>",
            install_server = "i",
            update_server = "u",
            check_server_version = "c",
            update_all_servers = "U",
            check_outdated_servers = "C",
            uninstall_server = "X",
            cancel_installation = "<C-c>",
          },
        },

        max_concurrent_installers = 10,
      }
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "mason")
      require("mason").setup(opts)

      -- custom nvchad cmd to install all mason binaries listed
      vim.api.nvim_create_user_command("MasonInstallAll", function()
        vim.cmd("MasonInstall " .. table.concat(opts.ensure_installed, " "))
      end, {})

      vim.g.mason_binaries_list = opts.ensure_installed
    end,
  },

  {
    "neovim/nvim-lspconfig",
    init = function()
      require("utils").lazy_load "nvim-lspconfig"
    end,
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        config = function()
          local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
          local null_ls = require "null-ls"
          local b = null_ls.builtins

          local sources = {
            b.formatting.prettierd.with {
              filetypes = { "html", "markdown", "css", "typescript", "javascript", "json", "graphql" },
            },
            b.formatting.eslint_d,
            -- null_ls.builtins.formatting.prettierd,
            -- null_ls.builtins.diagnostics.eslint_d.with {
            --   diagnostics_format = "[eslint] #{m}\n(#{c})",
            -- },
            -- b.formatting.prismaFmt,
            -- Lua
            b.formatting.stylua,
          }

          local lsp_formatting = function(bufnr)
            vim.lsp.buf.format {
              filter = function(client)
                return client.name == "null-ls"
              end,
              bufnr = bufnr,
            }
          end

          -- format on save
          null_ls.setup {
            debug = false,
            sources = sources,
            on_attach = function(client, bufnr)
              if client.supports_method "textDocument/formatting" then
                vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                vim.api.nvim_create_autocmd("BufWritePre", {
                  group = augroup,
                  buffer = bufnr,
                  callback = function()
                    lsp_formatting(bufnr)
                  end,
                })
              end
            end,
          }

          vim.api.nvim_create_user_command("DisableLspFormatting", function()
            vim.api.nvim_clear_autocmds { group = augroup, buffer = 0 }
          end, { nargs = 0 })
        end,
      },
    },
    config = function()
      require "plugins.configs.lspconfig"
      require("utils").load_mappings "lspconfig"
      -- require "custom.configs.lspconfig"
    end, -- Override to setup mason-lspconfig
  },

  -- load luasnips + cmp related in insert mode only
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {

      {
        -- snippet plugin
        "L3MON4D3/LuaSnip",
        -- dependencies = "rafamadriz/friendly-snippets",
        -- opts = { history = true, updateevents = "TextChanged,TextChangedI" },
        -- config = function(_, opts)
        --   require("luasnip").config.set_config(opts)
        --
        --   -- vscode format
        --   require("luasnip.loaders.from_vscode").lazy_load()
        --   require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }
        --
        --   -- snipmate format
        --   require("luasnip.loaders.from_snipmate").load()
        --   require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }
        --
        --   -- lua format
        --   require("luasnip.loaders.from_lua").load()
        --   require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }
        --
        --   vim.api.nvim_create_autocmd("InsertLeave", {
        --     callback = function()
        --       if
        --         require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
        --         and not require("luasnip").session.jump_active
        --       then
        --         require("luasnip").unlink_current()
        --       end
        --     end,
        --   })
        -- end,
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
      return require "plugins.configs.cmp"
    end,
    config = function(_, opts)
      require("cmp").setup(opts)
    end,
  },

  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
    init = function()
      require("utils").load_mappings "comment"
    end,
    config = function(_, opts)
      require("Comment").setup(opts)
    end,
  },

  -- file managing , picker etc
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    cmd = { "NvimTreeToggle", "NvimTreeFocus" },
    init = function()
      require("utils").load_mappings "nvimtree"
    end,
    opts = function()
      return require "plugins.configs.nvimtree"
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "nvimtree")
      require("nvim-tree").setup(opts)
      vim.api.nvim_create_autocmd({ "BufEnter" }, {
        pattern = "NvimTree*",
        callback = function()
          local view = require "nvim-tree.view"
          local is_visible = view.is_visible()

          local api = require "nvim-tree.api"
          if not is_visible then
            api.tree.open()
          end
        end,
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      { "nvim-telescope/telescope-fzy-native.nvim" },
      -- { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      { "nvim-telescope/telescope-frecency.nvim" },
      "jedrzejboczar/possession.nvim",
    },
    cmd = "Telescope",
    init = function()
      require("utils").load_mappings "telescope"
    end,
    opts = function()
      return require "plugins.configs.telescope"
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "telescope")
      local telescope = require "telescope"
      telescope.setup(opts)

      -- load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
    end,
  },

  -- Only load whichkey after all the gui
  {
    "folke/which-key.nvim",
    keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g", "f" },
    init = function()
      require("utils").load_mappings "whichkey"
    end,
    cmd = "WhichKey",
    config = function(_, opts)
      require("which-key").setup(opts)
    end,
  },
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
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
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("lspsaga").setup {
        diagnostic = {
          max_show_width = 0.4,
          max_width = 0.4,
        },
      }
    end,
  },

  {
    "jedrzejboczar/possession.nvim",
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

  {
    "goolord/alpha-nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("alpha").setup(require("plugins/configs/startify").config)
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
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   config = function()
  --     require("chatgpt").setup {
  --       api_key_cmd = "op read op://Personal/OpenAI/credential --no-newline",
  --     }
  --     local wk = require "which-key"
  --     wk.register({
  --       c = {
  --         name = "ChatGPT",
  --         c = { "<cmd>ChatGPT<CR>", "ChatGPT", mode = { "n", "v" } },
  --         e = { "<cmd>ChatGPTEditWithInstruction<CR>", "Edit with instruction", mode = { "n", "v" } },
  --         g = { "<cmd>ChatGPTRun grammar_correction<CR>", "Grammar Correction", mode = { "n", "v" } },
  --         t = { "<cmd>ChatGPTRun translate<CR>", "Translate", mode = { "n", "v" } },
  --         k = { "<cmd>ChatGPTRun keywords<CR>", "Keywords", mode = { "n", "v" } },
  --         d = { "<cmd>ChatGPTRun docstring<CR>", "Docstring", mode = { "n", "v" } },
  --         a = { "<cmd>ChatGPTRun add_tests<CR>", "Add Tests", mode = { "n", "v" } },
  --         o = { "<cmd>ChatGPTRun optimize_code<CR>", "Optimize Code", mode = { "n", "v" } },
  --         s = { "<cmd>ChatGPTRun summarize<CR>", "Summarize", mode = { "n", "v" } },
  --         f = { "<cmd>ChatGPTRun fix_bugs<CR>", "Fix Bugs", mode = { "n", "v" } },
  --         x = { "<cmd>ChatGPTRun explain_code<CR>", "Explain Code", mode = { "n", "v" } },
  --         r = { "<cmd>ChatGPTRun roxygen_edit<CR>", "Roxygen Edit", mode = { "n", "v" } },
  --         l = {
  --           "<cmd>ChatGPTRun code_readability_analysis<CR>",
  --           "Code Readability Analysis",
  --           mode = { "n", "v" },
  --         },
  --       },
  --     }, {
  --       prefix = "<leader>",
  --       mode = "v",
  --     })
  --   end,
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "nvim-telescope/telescope.nvim",
  --   },
  -- },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-telescope/telescope.nvim", -- optional
      "sindrets/diffview.nvim", -- optional
      "ibhagwan/fzf-lua", -- optional
    },
    config = true,
  },

  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    opts = {},
    config = function()
      require("typescript-tools").setup {
        settings = {
          -- spawn additional tsserver instance to calculate diagnostics on it
          separate_diagnostic_server = false,
          -- "change"|"insert_leave" determine when the client asks the server about diagnostic
          publish_diagnostic_on = "insert_leave",
        },
      }
    end,
  },
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      "smoka7/hydra.nvim",
    },
    opts = {},
    cmd = { "MCstart", "MCvisual", "MCclear", "MCpattern", "MCvisualPattern", "MCunderCursor" },
    keys = {
      {
        mode = { "v" },
        "<C-F>",
        "<cmd>MCstart<cr>",
        desc = "Multi cursor start",
      },
    },
    config = function()
      local N = require "multicursors.normal_mode"
      require("multicursors").setup {
        normal_leys = {
          ["<C-f>"] = { method = N.find_next, opts = { desc = "Find next" } },
        },
      }

      vim.api.nvim_set_hl(0, "MultiCursor", { bg = "#FFD700" })
      vim.api.nvim_set_hl(0, "MultiCursorMain", { bg = "#FFD700" })
    end,
  },
  {
    "NvChad/nvterm",
    config = function()
      require("nvterm").setup()
      require("utils").load_mappings "nvterm"
    end,
  },
}

require "plugins.autoroot"
require "plugins.edit_neovim"

require("lazy").setup(plugins, {
  -- defaults = { lazy = true },
  install = { colorscheme = { "kanagawa" } },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
})
