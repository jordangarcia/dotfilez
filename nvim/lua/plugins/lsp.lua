---@type LazyPluginSpec[]
return {
  {
    "jose-elias-alvarez/null-ls.nvim",
    lazy = true,
    event = "LspAttach",
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
              -- "jsonc",
              "yaml",
              "markdown",
              "graphql",
              "md",
              "txt",
            },
          },
          null_ls.builtins.formatting.ruff,
          null_ls.builtins.formatting.stylua,
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
    event = "UIEnter",
    lazy = true,
    dependencies = {
      -- format & linting
      { "yioneko/nvim-vtsls" },
    },

    config = function()
      require "plugins.configs.lspconfig"
      vim.api.nvim_create_autocmd({ "BufRead", "BufWinEnter", "BufNewFile" }, {
        callback = function()
          local file = vim.fn.expand "%"
          local condition = file ~= "NvimTree_1" and file ~= "[lazy]" and file ~= ""
          if condition then
            vim.schedule(function()
              vim.cmd "silent! do FileType"
            end)
          end
        end,
      })

      vim.schedule(function()
        vim.cmd "silent! LspStart"
      end)
    end,
  },
}
