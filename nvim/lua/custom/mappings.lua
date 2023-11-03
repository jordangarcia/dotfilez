---@type MappingsTable
local M = {}

-- this only works for when the clipboard is not setup
local set_clipboard = function()
  vim.cmd [[ call system('pbcopy', @+ ]]
end

-- diasable default nvchad binds
M.disabled = {
  -- lspconfig
  n = {
    ["gD"] = "",
    ["gd"] = "",
    ["K"] = "",
    ["j"] = "",
    ["k"] = "",
    ["gi"] = "",
    ["<leader>cc"] = "",
    ["<leader>y"] = "",
    ["<leader>b"] = "",
    ["<leader>cm"] = "",
    ["<leader>ls"] = "",
    ["<leader>D"] = "",
    ["<leader>ra"] = "",
    ["<leader>ca"] = "",
    ["gr"] = "",
    ["<leader>lf"] = "",
    ["<leader>q"] = "",
    ["<leader>wa"] = "",
    ["<leader>wr"] = "",
    ["<leader>wl"] = "",
    ["<leader>fm"] = "",
    ["<tab>"] = "",
    ["<S-tab>"] = "",
    ["<leader>x"] = "",
    ["<leader>wk"] = "",
    ["<leader>wK"] = "",
  },
  v = {
    ["<leader>ca"] = "",
  },
}

M.general = {
  n = {
    -- scrolling
    ["n"] = { "nzzzv" },
    ["N"] = { "Nzzzv" },
    ["<C-o>"] = { "<C-o>zz" },
    ["<C-i>"] = { "<C-i>zz" },

    ["<S-i>"] = {
      function()
        vim.cmd [[ Inspect ]]
      end,
      "Inspect",
    },
    ["<A-up>"] = { ":m .-2<CR>==", "Move line up" },
    ["<A-down>"] = { ":m .+1<CR>==", "Move line down" },
    ["<Esc>"] = { "<cmd> noh <CR>", "Clear highlights" },

    -- yank things
    ["<leader>yf"] = {
      function()
        vim.cmd [[ let @+=expand('%') ]]
      end,
      "[Y]ank [f]ile path to keyboard",
    },

    ["<leader>yy"] = {
      function()
        set_clipboard()
      end,
      "Yank -> Clipboard",
    },

    -- scrolling
    ["<leader>tn"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    ["<leader>tp"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    ["<leader>te"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    ["<leader>tt"] = { "<cmd> tabNext <CR>", "[Tab] Nex[T]" },
    ["<leader>tq"] = { "<cmd> tabc <CR>", "[T]ab [q]uit" },

    -- splitting
    ["<leader>v"] = { "<CMD> vsplit +enew <CR>", "v pslit" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    ["<C-Left>"] = { "<CMD> vertical resize +3 <CR>", "Increase horiz size", opts = { silent = true } },
    ["<C-Right>"] = { "<CMD> vertical resize -3 <CR>", "Increase horiz size", opts = { silent = true } },
    ["<C-Up>"] = { "<CMD> horizontal resize +3 <CR>", "Increase horiz size", opts = { silent = true } },
    ["<C-Down>"] = { "<CMD> horizontal resize -3 <CR>", "Increase horiz size", opts = { silent = true } },

    -- Quitting
    ["<c-q>"] = { "", "Quit" },
    ["<c-q><c-q>"] = { "<cmd> qa! <CR>", "Force [q]uit" },
    ["<c-q><c-w>"] = { "<cmd> wqa! <CR>", "Force [q]uit and [w]rite" },
    ["<leader>qw"] = { "<cmd> wqa! <CR>", "Quit and [w]rite all" },

    -- window things
    ["<leader>wo"] = {
      require("custom.buffer_utils").close_other_windows,
      "Window [o]nly",
    },
    ["<leader>wh"] = {
      require("custom.buffer_utils").close_hidden_buffers,
      "Close [h]idden buffers",
    },
    ['<C-w>"'] = { "<cmd> split <CR>", "Split window horizontally" },
    ["<C-w>v"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>s"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>k"] = { "", "" },

    ["<leader>wq"] = {
      require("custom.buffer_utils").smart_close_window,
      "[W]indow [q]uit",
    },
    ["<leader>wv"] = { "<CMD> vs <CR>", "New [v]ertical window" },
    -- close buffer + hide terminal buffer
    ["<leader>q"] = {
      require("custom.buffer_utils").smart_close_buffer,
      "Close buffer",
    },
    ["<C-w>q"] = {
      require("custom.buffer_utils").smart_close_buffer,
      "Close buffer",
    },
    ["<leader>bh"] = {
      require("custom.buffer_utils").close_hidden_buffers,
      "Close hidden buffers",
    },
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
    -- ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    -- ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
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
      function()
        require("lspsaga.diagnostic"):goto_next {
          severity = 1, -- error
        }
      end,
      "Goto next error",
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

M.nvimtree = {
  plugin = true,

  n = {
    -- toggle
    ["<C-e>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },
    -- focus
    ["<leader>e"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
    ["<C-0>"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  v = {
    ["<leader>fw"] = {
      "<cmd> Telescope grep_string <CR>",
      "Live grep",
    },
  },
  n = {
    ["<C-P>"] = {
      function()
        print("searching in cwd" .. vim.fn.getcwd())
        require("telescope").extensions.smart_open.smart_open {
          prompt_title = require("custom.path_utils").normalize_to_home(vim.fn.getcwd()),
          cwd = vim.fn.getcwd(),
          cwd_only = true,
        }
      end,
      "Find smart open",
    },
    ["<C-S-P>"] = {
      function()
        require("telescope").extensions.harpoon.marks {
          layout_strategy = "vertical",
          layout_config = { prompt_position = "top", width = 0.3, height = 0.4 },
        }
      end,
      "Find harpoon",
    },
    ["<C-S-O>"] = {
      function()
        require("telescope.builtin").builtin()
      end,
      "Find builtins",
    },
    ["<C-b>"] = {
      "<cmd> Telescope buffers sort_mru=true cwd_only=true <CR>",
      "Find buffers",
    },
    ["<C-t>"] = {
      function()
        require("telescope.builtin").lsp_dynamic_workspace_symbols {
          ignore_symbols = { "property ", "variable" },
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

    ["<leader>fz"] = {
      function()
        require("telescope").extensions.zoxide.list {
          layout_strategy = "vertical",
          layout_config = { prompt_position = "top", width = 0.3, height = 0.4 },
        }
      end,
      "Find [z]oxide",
    },
    -- ["<leader>fz"] = { "<cmd> Telescope zoxide list <CR>", "Find [z]oxide" },
    ["<leader>fs"] = {
      function()
        require("telescope").load_extension "possession"
        require("telescope").extensions.possession.list()
      end,
      "Find sessions",
    },
    ["<leader>fm"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },

    -- git = also combined with git

    -- pick a hidden term
    -- ["<leader>pt"] = { "<cmd> Telescope terms <CR>", "Pick hidden term" },

    -- theme switcher
    -- ["<leader>ft"] = { "<cmd> Telescope themes <CR>", "Nvchad themes" },
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

  n = {},
}

M.whichkey = {
  plugin = true,

  n = {
    ["<leader>?"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "Which-key all keymaps",
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

    ["<leader>gc"] = { "<cmd> Telescope git_commits <CR>", "Git commits (telescope)" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "Git status (telescope)" },
    ["<leader>gz"] = {
      function()
        vim.cmd "Gitsigns toggle_signs"
      end,
      "[G]itsigns toggle [z]enmode",
    },
  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<S-l>"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },

    ["<S-h>"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },
  },
}

M.harpoon = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<leader>h1"] = {
      function()
        require("harpoon.ui").nav_file(1)
      end,
      "[H]arpoon file [1]",
    },
    ["<leader>h2"] = {
      function()
        require("harpoon.ui").nav_file(2)
      end,
      "[H]arpoon file [2]",
    },
    ["<leader>h3"] = {
      function()
        require("harpoon.ui").nav_file(3)
      end,
      "[H]arpoon file [3]",
    },
    ["<leader>h4"] = {
      function()
        require("harpoon.ui").nav_file(4)
      end,
      "[H]arpoon file [4]",
    },
    ["<leader>h5"] = {
      function()
        require("harpoon.ui").nav_file(5)
      end,
      "[H]arpoon file [5]",
    },
    ["<leader>ha"] = {
      function()
        require("harpoon.mark").add_file()
      end,
      "[H]arpoon [a]dd",
    },
  },
}

M.fugitive = {
  n = {
    ["<leader>gd"] = { "<cmd> Gvdiffsplit <cr>", desc = "Git [d]iff" },
    ["<leader>gb"] = { "<cmd> Git blame <cr>", desc = "Git [b]lame" },
    ["<leader>gg"] = { "<cmd> Git <cr>", desc = "Git git" },
    ["<leader>gl"] = { "<cmd> Gclog <cr>", desc = "Git [l]og" },
    ["<leader>g3"] = { "<cmd> Gvdiffsplit! <cr>", desc = "Git diff [3]way" },
  },
}

return M
