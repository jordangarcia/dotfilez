return function()
  require("lspsaga").setup {
    diagnostic = {
      max_show_width = 0.4,
      max_width = 0.4,
    },
    lightbulb = {
      enable = false,
    },
    finder = {
      left_width = 0.7,
      right_width = 0.7,
      keys = {
        toggle_or_open = "<CR>",
        vsplit = "s",
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
  require("which-key").register({
    l = {
      name = "Lsp",
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
      r = {
        function()
          vim.lsp.buf.references()
        end,
        "Lsp [r]eferences",
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
      t = { "<cmd> Lspsaga peek_type_definition <CR>", "Lspsaga [t]ype definition" },
      a = { "<cmd> Lspsaga code_action <CR>", "Lspsaga code [a]ction" },
      -- use ]d and [d
      -- n = { "<cmd> Lspsaga diagnostic_jump_next <CR>", "Lspsaga [n]ext diagnostic" },
      -- p = { "<cmd> Lspsaga diagnostic_jump_prev <CR>", "Lspsaga [p]rev diagnostic" },
      ["wa"] = {
        function()
          vim.lsp.buf.add_workspace_folder()
        end,
        "Add workspace folder",
      },

      ["wr"] = {
        function()
          vim.lsp.buf.remove_workspace_folder()
        end,
        "Remove workspace folder",
      },

      ["wl"] = {
        function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end,
        "List workspace folders",
      },
      ["<C-r>"] = { "<cmd> LspRestart <CR>", "Lsp[R]estart" },
    },
  }, {
    prefix = "<leader>",
    mode = { "n", "v" },
  })
end
