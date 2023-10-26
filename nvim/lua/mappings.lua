local M = {}

local set_clipboard = function()
  vim.cmd("call system('pbcopy', @+)", { silent = true })
end

-- get rid of command history
vim.api.nvim_set_keymap("n", "q:", "<nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "q:", "<nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "q:", "<nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "q:", "<nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "Q", "<nop>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "Q", "<nop>", { noremap = true, silent = true })

-- better
-- vim.api.nvim_set_keymap("<leader>y", "Q", "<nop>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("t", "Q", "<nop>", { noremap = true, silent = true })
-- vim.api.nvim_set_keymap("t", "Q", "<nop>", { noremap = true, silent = true })

M.general = {
  i = {
    -- go to  beginning and end
    ["<C-b>"] = { "<ESC>^i", "Beginning of line" },
    ["<C-e>"] = { "<End>", "End of line" },

    -- navigate within insert mode
    ["<C-h>"] = { "<Left>", "Move left" },
    ["<C-l>"] = { "<Right>", "Move right" },
    ["<C-j>"] = { "<Down>", "Move down" },
    ["<C-k>"] = { "<Up>", "Move up" },
  },

  n = {
    ["<A-up>"] = { ":m .-2<CR>==", "Move line up" },
    ["<A-down>"] = { ":m .+1<CR>==", "Move line down" },
    ["<leader>|"] = { "<CMD> vsplit +enew <CR>", "v pslit" },
    ["<leader>s"] = { "<CMD> vsplit +enew <CR>", "v pslit" },
    -- [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<Esc>"] = { "<cmd> noh <CR>", "Clear highlights" },
    -- switch between windows
    ["<C-f>"] = {
      "",
      { noremap = true, silent = true },
    },
    ["<S-l>"] = {
      "<CMD> bn <CR>",
      { noremap = true, silent = true },
    },
    ["<S-h>"] = {
      "<CMD> bp <CR>",
      { noremap = true, silent = true },
    },

    ["<leader>y"] = {
      function()
        set_clipboard()
      end,
      "Yank -> Clipboard",
    },
    ["<leader>q"] = { "<cmd> q <CR>", "Close Window" },
    ['<C-w>"'] = { "<cmd> split <CR>", "Split window horizontally" },
    ["<C-w>v"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>s"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>k"] = { "", "" },
    ["<leader>tn"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    ["<leader>tp"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    ["<leader>te"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    -- tmux window stuff
    ["<C-h>"] = { "<cmd> NvimTmuxNavigateLeft <CR>", "Window left" },
    ["<C-j>"] = { "<cmd> NvimTmuxNavigateDown <CR>", "Window down" },
    ["<C-k>"] = { "<cmd> NvimTmuxNavigateUp <CR>", "Window up" },
    ["<C-l>"] = { "<cmd> NvimTmuxNavigateRight <CR>", "Window right" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    -- Copy all
    --    ["<C-c>"] = { "<cmd> %y+ <CR>", "Copy whole file" },

    -- line numbers
    --["<leader>n"] = { "<cmd> set nu! <CR>", "Toggle line number" },
    -- ["<leader>rn"] = { "<cmd> set rnu! <CR>", "Toggle relative number" },

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },

    -- new buffer
    ["<leader>b"] = { "<cmd> enew <CR>", "New buffer" },
    ["<leader>ch"] = { "<cmd> Telescope keymaps <CR>", "Keymaps" },

    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format { async = true }
      end,
      "LSP formatting",
    },
  },

  t = {
    ["<F1>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
    ["<C-w>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
  },

  v = {
    ["<A-down>"] = { ":m '>+1<CR>gv=gv", "Move lines down" },
    ["<A-up>"] = { ":m '<-2<CR>gv=gv", "Move lines up" },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["<"] = { "<gv", "Indent line" },
    [">"] = { ">gv", "Indent line" },
  },

  x = {
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },
  },
}

M.comment = {
  plugin = true,

  -- toggle comment in both modes
  n = {
    ["<C-/>"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "Toggle comment",
    },
  },

  v = {
    -- tmux support :/
    ["<C-_>"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "Toggle comment",
    },
    ["<C-/>"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "Toggle comment",
    },
  },
}

M.lspconfig = {
  plugin = true,

  -- See `<cmd> :help vim.lsp.*` for documentation on any of the below functions

  n = {
    ["<F2>"] = { "<cmd> Lspsaga rename <CR>", "Lspsaga [r]ename" },

    ["<F11>"] = {
      "<cmd> Lspsaga finder tyd+def+ref <CR>",
      "Lspsaga finder",
    },

    ["<F12>"] = {
      "<cmd> Telescope lsp_definitions <CR>",
      "LSP definition",
    },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "LSP hover",
    },

    ["<C-.>"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "LSP code action",
    },

    ["<C-n>"] = {
      "<cmd> Lspsaga diagnostic_jump_next <CR>",
      "Goto next",
    },

    ["<leader>wa"] = {
      function()
        vim.lsp.buf.add_workspace_folder()
      end,
      "Add workspace folder",
    },

    ["<leader>wr"] = {
      function()
        vim.lsp.buf.remove_workspace_folder()
      end,
      "Remove workspace folder",
    },

    ["<leader>wl"] = {
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      "List workspace folders",
    },
  },
}

M.copilot = {
  i = {
    ["<C-l>"] = {
      function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept_line()
        end
      end,
      "Copilot accept",
    },
  },
}

M.tmu = {
  n = {},
}

M.nvimtree = {
  plugin = true,

  n = {
    -- toggle
    ["<C-e>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
    ["<leader>d"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },

    -- focus
    ["<C-0>"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  n = {
    ["<C-P>"] = { "<cmd> Telescope frecency workspace=CWD <CR>", "Find frecency" },
    ["<C-S-P>"] = { "<cmd> Telescope oldfiles cwd_only=true <CR>", "Find oldfiles" },
    ["<C-S-O>"] = { "<cmd> Telescope builtin <CR>", "Find builtins" },
    ["<C-b>"] = {
      "<cmd> Telescope buffers sort_mru=true ignore_current_buffer=true cwd_only=true <CR>",
      "Find buffers",
    },
    ["<C-t>"] = {
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols {
          ignore_symbols = { "property", "variable" },
        }
      end,
      "Find symbols",
    },
    ["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "Find oldfiles" },
    ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>ff"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<leader>fd"] = {
      "<cmd> Telescope lsp_document_symbols follow=true no_ignore=true hidden=true <CR>",
      "Find all",
    },
    ["<leader>fw"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
    ["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "Find buffers" },
    ["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "Help page" },
    ["<leader>fz"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },
    ["<leader>fs"] = {
      function()
        require("telescope").load_extension "possession"
        require("telescope").extensions.possession.list()
      end,
      "Find sessions",
    },

    -- git = also combined with git
    ["<leader>gc"] = { "<cmd> Telescope git_commits <CR>", "Git commits" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "Git status" },
    ["<leader>gg"] = { "<cmd> Neogit <CR>", "Neogit" },

    -- pick a hidden term
    -- ["<leader>pt"] = { "<cmd> Telescope terms <CR>", "Pick hidden term" },

    -- theme switcher
    ["<leader>ft"] = { "<cmd> Telescope themes <CR>", "Nvchad themes" },

    -- ["<leader>fm"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },
  },
}

M.nvterm = {
  plugin = true,

  t = {
    -- toggle in terminal mode
    ["<C-\\>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },
  },

  n = {
    -- -- toggle in normal mode
    -- ["<C-\\>"] = {
    --   function()
    --     require("nvterm.terminal").toggle "vertical"
    --   end,
    --   "Toggle vertical term",
    -- },
    -- ["<A-i>"] = {
    --   function()
    --     require("nvterm.terminal").toggle "float"
    --   end,
    --   "Toggle floating term",
    -- },
    --
    -- ["<A-h>"] = {
    --   function()
    --     require("nvterm.terminal").toggle "horizontal"
    --   end,
    --   "Toggle horizontal term",
    -- },
    --
    -- ["<A-v>"] = {
    --   function()
    --     require("nvterm.terminal").toggle "vertical"
    --   end,
    --   "Toggle vertical term",
    -- },

    -- new
    -- ["<leader>h"] = {
    --   function()
    --     require("nvterm.terminal").new "horizontal"
    --   end,
    --   "New horizontal term",
    -- },

    -- ["<leader>v"] = {
    --   function()
    --     require("nvterm.terminal").new "vertical"
    --   end,
    --   "New vertical term",
    -- },
  },
}

M.whichkey = {
  plugin = true,

  n = {
    ["<leader>wK"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "Which-key all keymaps",
    },
    ["<leader>wk"] = {
      function()
        local input = vim.fn.input "WhichKey: "
        vim.cmd("WhichKey " .. input)
      end,
      "Which-key query lookup",
    },
  },
}

M.gitsigns = {
  plugin = true,

  n = {
    -- Actions
    ["<leader>rh"] = {
      function()
        require("gitsigns").reset_hunk()
      end,
      "Reset hunk",
    },

    ["<leader>ph"] = {
      function()
        require("gitsigns").preview_hunk()
      end,
      "Preview hunk",
    },
  },
}

return M
