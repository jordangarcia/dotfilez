---@type LazyPluginSpec[]
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
        -- "ruff-lsp",
        "ruff",
        "basedpyright",
        -- c/cpp stuff
        "clangd",
        "clang-format",

        -- toml
        "taplo",
      },
    },
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
    keys = {
      {
        "<leader>tf",
        function()
          -- check if disable_format_on_save is set
          if vim.b.disable_format_on_save then
            vim.b.disable_format_on_save = nil
            vim.notify "format_on_save: enabled"
          else
            vim.b.disable_format_on_save = true
            vim.notify "format_on_save: disabled"
          end
        end,
        desc = "Toggle format on save",
      },
    },
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
              if vim.b.disable_format_on_save then
                return
              end
              -- TODO create a keybind that toggles format on save right
              vim.lsp.buf.format { bufnr = ev.buf, async = false }
            end,
          })
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
          enable = true,
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
      -- vim.api.nvim_command "highlight clear SagaNormal"
      -- vim.api.nvim_command "highlight link SagaNormal Normal"

      -- vim.cmd [[ nnoremap <leader>li mF:%!cd ../../ && eslint_d --stdin --fix-to-stdout<CR>`F ]]
      --

      require("which-key").add {
        {
          mode = { "n", "v" },
          {
            "]d",
            function()
              vim.diagnostic.goto_next {
                float = false,
              }
            end,
            desc = "[n]ext diagnostic",
          },
          {
            "[d",
            function()
              vim.diagnostic.goto_prev {
                float = false,
              }
            end,
            desc = "[p]rev diagnostic",
          },
          {
            "<C-2>",
            "<cmd> Lspsaga rename <CR>",
            desc = "Lspsaga [r]ename",
          },
          {
            "<F11>",
            "<cmd> Lspsaga finder tyd+def+ref <CR>",
            -- function()
            --   require("telescope.builtin").lsp_references {
            --     include_declaration = true,
            --     jump_type = "never",
            --   }
            -- end,
            desc = "LSP References",
          },
          {
            "<F12>",
            "<cmd> Lspsaga goto_definition <CR>",
            -- function()
            --   vim.lsp.buf.definition()
            -- end,
            desc = "LSP definition",
          },
          {
            "<F24>",
            [[ :exec "vert norm <C-V><C-W>]"<CR> ]],
            desc = "Jump to def (vsplit)",
          },
          {
            "K",
            function()
              vim.lsp.buf.hover()
            end,
            desc = "LSP hover",
          },
        },
      }
      require("which-key").add {
        {
          mode = { "n", "v" },
          {
            "<leader>lR",
            function()
              vim.lsp.buf.references()
            end,
            desc = "Lsp [R]eferences",
          },
          { "<leader>ld", group = "type definition" },
          {
            "<leader>ldp",
            function()
              require("telescope.builtin").lsp_type_definitions {
                jump_type = "never",
                layout_config = {
                  height = 0.4,
                },
              }
            end,
            desc = "Lsp [d]efinition [p]eek",
          },
          {
            "<leader>ldt",
            function()
              require("telescope.builtin").lsp_type_definitions { jump_type = "tab" }
            end,
            desc = "Lsp [d]efinition [t]ab",
          },
          {
            "<leader>ldv",
            function()
              require("telescope.builtin").lsp_type_definitions { jump_type = "vsplit" }
            end,
            desc = "Lsp [d]efinition [v]split",
          },
          {
            "<leader>lf",
            function()
              vim.lsp.buf.format { async = true }
            end,
            desc = "Lsp [f]ormat",
          },
          {
            "<leader>li",
            "<CMD> EslintFixAll <CR>",
            desc = "Eslint f[i]x all",
          },
          {
            "<leader>ls",
            function()
              vim.lsp.buf.signature_help()
            end,
            desc = "Lsp [s]ignature",
          },
          { "<leader>lt", group = "typescript" },
          {
            "<leader>lti",
            function()
              vim.lsp.buf.code_action {
                apply = true,
                context = {
                  only = { "source.removeUnusedImports" },
                  diagnostics = {},
                },
              }
            end,
            desc = "TS remove unused imports",
          },
        },
      }
    end,
  },
}
