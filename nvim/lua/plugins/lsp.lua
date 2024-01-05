-- max_width = 0.4,
return {
  {
    "williamboman/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonInstallAll", "MasonUpdate" },
    opts = {
      ensure_installed = {
        -- lua stuff
        "lua-language-server",
        "stylua",

        -- web dev stuff
        "css-lsp",
        "html-lsp",
        "typescript-language-server",
        "prettier",
        "eslint-lsp",
        "prisma-language-server",
        "graphql-language-service-cli",
        "json-lsp",
        "terraform-ls",

        -- python stuff
        "pyright",
        "black",
        "ruff-lsp",
        -- c/cpp stuff
        "clangd",
        "clang-format",
      },
    },
    config = function(_, opts)
      dofile(vim.g.base46_cache .. "mason")
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
    dependencies = {
      -- format & linting
      {
        "jose-elias-alvarez/null-ls.nvim",
        enabled = true,
        opts = function()
          local null_ls = require "null-ls"
          return {
            debug = false,
            sources = {
              null_ls.builtins.formatting.prettier.with {
                filetypes = {
                  "typescriptreact",
                  "javascript",
                  "typescript",
                  "css",
                  "scss",
                  "html",
                  "json",
                  "jsonc",
                  "yaml",
                  "markdown",
                  "graphql",
                  "md",
                  "txt",
                },
              },
              null_ls.builtins.formatting.stylua,
              null_ls.builtins.formatting.black,
            },
            on_attach = function(client, bufnr)
              -- this is buggy, instead just setup an auto cmd for EVERYTHING
              -- that saves
              -- if client.supports_method "textDocument/formatting" then
              --   local augroup = vim.api.nvim_create_augroup("Format", {})
              --
              --   vim.api.nvim_clear_autocmds {
              --     group = augroup,
              --     buffer = bufnr,
              --   }
              --   vim.api.nvim_create_autocmd("BufWritePre", {
              --     group = augroup,
              --     buffer = bufnr,
              --     callback = function()
              --       print("null ls formatting" .. bufnr)
              --       vim.lsp.buf.format { bufnr = bufnr, async = false }
              --     end,
              --   })
              -- end
            end,
          }
        end,
        config = function(_, opts)
          local null_ls = require "null-ls"
          null_ls.setup(opts)

          vim.api.nvim_create_autocmd("BufWritePre", {
            callback = function(ev)
              vim.lsp.buf.format { bufnr = ev.buf, async = false }
            end,
          })
        end,
      },
      {
        "pmizio/typescript-tools.nvim",
        enabled = false,
        -- event = "LspAttach",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
          local api = require "typescript-tools.api"
          require("typescript-tools").setup {
            -- this shouldn't be needed now
            -- root_dir = require("lspconfig.util").root_pattern ".git",
            on_attach = require("plugins.configs.lspconfig").on_attach,
            settings = {
              -- spawn additional tsserver instance to calculate diagnostics on it
              separate_diagnostic_server = false,
              -- "change"|"insert_leave" determine when the client asks the server about diagnostic
              -- publish_diagnostic_on = "insert_leve",
              tsserver_file_preferences = {
                -- autoImportFileExcludePatterns = { "**/dist/**" },
                importModuleSpecifierPreference = "relative",
              },
            },
            handlers = {

              documentFormattingProvider = true,
              documentHighlightProvider = true,
              ["textDocument/publishDiagnostics"] = api.filter_diagnostics { -- Ignore 'This may be converted to an async function' diagnostics.
                --conver to esm
                80001,
                80006,
                -- no implicit any on variable
                7043,
              },

              -- ["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
              --   severity_sort = true,
              --   virtual_text = false,
              -- }),
            },
          }
        end,
      },
    },
    init = function()
      require("core.utils").lazy_load "nvim-lspconfig"
    end,
    config = function()
      require "plugins.configs.lspconfig"
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    dependencies = {
      "folke/which-key.nvim",
    },
    event = "LspAttach",
    config = function()
      require("lspsaga").setup {
        diagnostic = {
          max_show_width = 0.9,
          max_width = 0.7,
        },
        lightbulb = {
          enable = false,
        },
        finder = {
          left_width = 0.7,
          right_width = 0.7,
          keys = {
            toggle_or_open = "<CR>",
            vsplit = "<C-v>",
            tabe = "<C-t>",
            shuttle = "<TAB>",
          },
        },
        symbol_in_winbar = {
          enable = false,
        },
      }
      vim.api.nvim_command "highlight clear SagaNormal"
      vim.api.nvim_command "highlight link SagaNormal Normal"

      -- vim.cmd [[ nnoremap <leader>li mF:%!cd ../../ && eslint_d --stdin --fix-to-stdout<CR>`F ]]
      --

      require("which-key").register({
        ["]d"] = { "<cmd> Lspsaga diagnostic_jump_next <CR>", "Lspsaga [n]ext diagnostic" },
        ["[d"] = { "<cmd> Lspsaga diagnostic_jump_prev <CR>", "Lspsaga [p]rev diagnostic" },
        ["<C-2>"] = { "<cmd> Lspsaga rename <CR>", "Lspsaga [r]ename" },

        ["<F11>"] = {
          "<cmd> Lspsaga finder tyd+def+ref <CR>",
          "Lspsaga finder",
        },

        ["<F12>"] = {
          "<cmd> Telescope lsp_definitions <CR>",
          "LSP definition",
        },
        -- open tag in new window
        ["<F24>"] = {
          [[ :exec "vert norm <C-V><C-W>]"<CR> ]],
          "Jump to def (vsplit)",
        },

        ["K"] = {
          function()
            vim.lsp.buf.hover()
          end,
          -- "<CMD> Lspsaga peek_type_definition <CR>",
          "LSP hover",
        },

        ["<C-n>"] = {
          function()
            require("lspsaga.diagnostic"):goto_next {
              severity = 1, -- error
            }
          end,
          "Goto next error",
        },
      }, {
        mode = { "n", "v" },
      })
      require("which-key").register({
        l = {
          name = "+lsp",
          -- f = { "<cmd> Lspsaga finder tyd+def+ref <CR>", "Lspsaga [f]inder" },
          o = { "<cmd> Lspsaga outline <CR>", "Lspsaga [o]utline" },
          -- r = { "<cmd> Lspsaga rename <CR>", "Lspsaga [r]ename" },
          -- f2 renames
          -- r = {
          --   function()
          --     require("nvchad.renamer").open()
          --   end,
          --   "Lspsaga [r]ename",
          -- },
          R = {
            function()
              vim.lsp.buf.references()
            end,
            "Lsp [R]eferences",
          },
          i = {
            "<CMD> EslintFixAll <CR>",
            "Eslint f[i]x all",
          },
          f = {
            function()
              vim.lsp.buf.format { async = true }
            end,
            "Lsp [f]ormat",
          },
          s = {
            function()
              vim.lsp.buf.signature_help()
            end,
            "Lsp [s]ignature",
          },
          d = { "<cmd> Lspsaga peek_definition <CR>", "Lspsaga [d]efinition" },
          D = { "<cmd> Lspsaga peek_type_definition <CR>", "Lspsaga type [D]efinition" },
          t = {
            name = "+typescript",
            i = {
              function()
                vim.lsp.buf.code_action {
                  apply = true,
                  context = {
                    only = { "source.removeUnusedImports.ts" },
                    diagnostics = {},
                  },
                }
              end,
              "TS remove unused imports",
            },
          },
          a = { "<cmd> Lspsaga code_action <CR>", "Lspsaga code [a]ction" },
          -- use ]d and [d
          -- n = { "<cmd> Lspsaga diagnostic_jump_next <CR>", "Lspsaga [n]ext diagnostic" },
          -- p = { "<cmd> Lspsaga diagnostic_jump_prev <CR>", "Lspsaga [p]rev diagnostic" },
        },
      }, {
        prefix = "<leader>",
        mode = { "n", "v" },
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
  {
    "mhanberg/output-panel.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>lO",
        function()
          vim.cmd [[ OutputPanel ]]
        end,
        desc = "Output panel",
      },
    },
    config = function()
      require("output_panel").setup()
    end,
  },
}
