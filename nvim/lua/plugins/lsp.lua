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
    event = "UIEnter",
    lazy = true,
    dependencies = {
      "williamboman/mason.nvim",
      -- format & linting
      { "yioneko/nvim-vtsls" },
    },

    config = function()
      -- Enable native LSP servers (configured via lsp/*.lua files)
      vim.lsp.enable {
        "html",
        "cssls",
        "taplo",
        "jsonls",
        "graphql",
        "eslint",
        "prismals",
        "terraformls",
        "pyright",
        "ruff",
        "lua_ls",
        "vtsls",
      }

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

      -- ESLint code actions on save for import fixes
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue" },
        callback = function(args)
          -- Respect the same format_on_save setting as Conform
          if vim.b[args.buf].disable_format_on_save then
            return
          end

          local params = vim.lsp.util.make_range_params(0, "utf-16")
          params.context = { only = { "source.fixAll.eslint" } }

          local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
          if result then
            for _, res in pairs(result) do
              if res.result then
                for _, action in pairs(res.result) do
                  if action.edit then
                    vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
                  end
                end
              end
            end
          end
        end,
      })
    end,
  },
}
