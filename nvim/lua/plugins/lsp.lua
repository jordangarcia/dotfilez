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
        -- "typescript-language-server",
        "vtsls",
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
        "basedpyright",
        -- c/cpp stuff
        "clangd",
        "clang-format",

        -- toml
        "taplo",
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
      { "yioneko/nvim-vtsls" },
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
              null_ls.builtins.formatting.ruff,
              null_ls.builtins.formatting.stylua,
              -- null_ls.builtins.formatting.taplo,
              -- null_ls.builtins.formatting.black,
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
              -- TODO create a keybind that toggles format on save right
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
          enable = false,
          max_show_width = 0.9,
          max_width = 0.7,
        },
        hover = {
          enable = false,
        },
        outline = {
          enable = false,
        },
        callhierarchy = {
          enable = false,
        },
        code_action = {
          enable = false,
        },
        implement = {
          enable = false,
        },

        definition = {
          enable = false,
        },

        lightbulb = {

          enable = false,
        },
        finder = {
          enable = false,
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
        ["]d"] = {
          function()
            vim.diagnostic.goto_next {
              float = false,
            }
          end,
          "[n]ext diagnostic",
        },
        ["[d"] = {
          function()
            vim.diagnostic.goto_prev {
              float = false,
            }
          end,
          "[p]rev diagnostic",
        },
        ["<C-2>"] = { "<cmd> Lspsaga rename <CR>", "Lspsaga [r]ename" },
        --

        ["<F11>"] = {
          function()
            require("telescope.builtin").lsp_references {
              include_declaration = true,
              jump_type = "never",
            }
          end,
          "LSP References ",
        },

        ["<F12>"] = {
          function()
            require("telescope.builtin").lsp_definitions {
              jump_type = "tab drop",
            }
          end,
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
      }, {
        mode = { "n", "v" },
      })
      require("which-key").register({
        l = {
          name = "+lsp",
          -- f = { "<cmd> Lspsaga finder tyd+def+ref <CR>", "Lspsaga [f]inder" },
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
          d = {
            name = "+type definition",
            p = {
              function()
                require("telescope.builtin").lsp_type_definitions {
                  jump_type = "never",
                  layout_config = {
                    height = 0.4,
                  },
                }
              end,
              "Lsp [d]efinition [p]eek",
            },
            t = {
              function()
                require("telescope.builtin").lsp_type_definitions { jump_type = "tab" }
              end,
              "Lsp [d]efinition [t]ab",
            },
            v = {
              function()
                require("telescope.builtin").lsp_type_definitions { jump_type = "vsplit" }
              end,
              "Lsp [d]efinition [v]split",
            },
          },

          -- D = {
          --   name = "+type definition",
          --   p = {
          --     function()
          --       require("telescope.builtin").lsp_type_definitions {
          --         jump_type = "never",
          --         layout_config = {
          --           height = 0.4,
          --         },
          --       }
          --     end,
          --     "Lsp [d]efinition [p]eek",
          --   },
          --   t = {
          --     function()
          --       require("telescope.builtin").lsp_type_definitions { jump_type = "tab" }
          --     end,
          --     "Lsp [d]efinition [t]ab",
          --   },
          --   v = {
          --     function()
          --       require("telescope.builtin").lsp_type_definitions { jump_type = "vsplit" }
          --     end,
          --     "Lsp [d]efinition [v]split",
          --   },
          -- },

          t = {
            name = "+typescript",
            i = {
              function()
                vim.lsp.buf.code_action {
                  apply = true,
                  context = {
                    only = { "source.removeUnusedImports" },
                    diagnostics = {},
                  },
                }
              end,
              "TS remove unused imports",
            },
          },
        },
      }, {
        prefix = "<leader>",
        mode = { "n", "v" },
      })
    end,
  },
  {
    -- this is now covered by the vstls-rename
    "antosha417/nvim-lsp-file-operations",
    enabled = false,
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
