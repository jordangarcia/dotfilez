---@type LazyPluginSpec
return {
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
        layout = "normal",
        left_width = 0.5,
        right_width = 1,
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
          -- "<cmd> Lspsaga finder tyd+def+ref <CR>",
          function()
            require("telescope.builtin").lsp_references {}
          end,
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
        -- {
        --   "K",
        --   function()
        --     vim.lsp.buf.hover()
        --   end,
        --   desc = "LSP hover",
        -- },
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
}
