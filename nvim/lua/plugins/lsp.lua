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
        "biome",

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
      -- Projects where ESLint is too slow to be useful in the editor. Lint runs in CI.
      local eslint_disabled_roots = {
        vim.fn.expand "~/code/gamma",
      }

      -- vim.lsp.config() outranks every lsp/*.lua on the runtimepath, including the one
      -- nvim-lspconfig ships. The root_dir decision must live here to take effect.
      vim.lsp.config("eslint", {
        root_dir = function(bufnr, on_dir)
          local util = require "lspconfig.util"
          local fname = vim.api.nvim_buf_get_name(bufnr)

          for _, root in ipairs(eslint_disabled_roots) do
            if fname:sub(1, #root + 1) == root .. "/" then
              return
            end
          end

          local eslint_root = util.root_pattern(
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.ts"
          )(fname)
          if not eslint_root then
            return
          end

          -- A closer biome or oxlint config wins over eslint.
          local other_root = util.root_pattern("biome.json", "biome.jsonc", ".oxlintrc.json")(fname)
          if not other_root then
            return on_dir(eslint_root)
          end

          local eslint_depth = #vim.split(eslint_root, "/", { plain = true })
          local other_depth = #vim.split(other_root, "/", { plain = true })

          if eslint_depth > other_depth then
            return on_dir(eslint_root)
          end
        end,
      })

      -- Enable native LSP servers (configured via lsp/*.lua files)
      vim.lsp.enable {
        "html",
        "cssls",
        "taplo",
        "jsonls",
        "graphql",
        "eslint",
        "biome",
        "prismals",
        "terraformls",
        "pyright",
        "ruff",
        "lua_ls",
        "vtsls",
        "tsgo",
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

          -- Only send to eslint, not all LSPs (tsgo doesn't support codeAction yet)
          local eslint = vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" })[1]
          if not eslint then
            return
          end

          local params = vim.lsp.util.make_range_params(0, "utf-16")
          params.context = { only = { "source.fixAll.eslint" } }

          local result = eslint.request_sync("textDocument/codeAction", params, 1000, args.buf)
          if result and result.result then
            for _, action in pairs(result.result) do
              if action.edit then
                vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
              end
            end
          end
        end,
      })
    end,
  },
}
