---@type MappingsTable
local M = {}

-- this only works for when the clipboard is not setup
local set_clipboard = function()
  vim.cmd [[ call system('pbcopy', @+ ]]
end

-- Don't move on *
vim.cmd [[ nnoremap * *<c-o> ]]

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
    -- get rid of all telescope defaults
    ["<leader>ff"] = "",
    ["<leader>fa"] = "",
    ["<leader>fw"] = "",
    ["<leader>fb"] = "",
    ["<leader>fh"] = "",
    ["<leader>fo"] = "",
    ["<leader>fz"] = "",
    ["<leader>cm"] = "",
    ["<leader>gt"] = "",
    ["<leader>pt"] = "",
    ["<leader>th"] = "",
    ["<leader>ma"] = "",

    -- gitsigns
    ["<leader>td"] = "",
    ["<leader>ph"] = "",
    ["<leader>rh"] = "",

    -- nvim-tree
    ["<C-n>"] = "",
    ["<leader>e"] = "",

    -- which key
    ["<leader>/"] = "",
    ["<leader>n"] = "",
    ["<leader>rn"] = "",
  },
  v = {
    ["<leader>ca"] = "",
    ["<leader>/"] = "",
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
    ["<leader><tab><tab>"] = { "<cmd> tabNext <CR>", "[Tab] Next]" },
    ["<leader><tab>n"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    ["<leader><tab>p"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    ["<leader><tab>e"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    ["<leader><tab>t"] = { "<cmd> tabNext <CR>", "[Tab] Nex[T]" },
    ["<leader><tab>q"] = { "<cmd> tabc <CR>", "[T]ab [q]uit" },
    -- ["<leader>tn"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    -- ["<leader>tp"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    -- ["<leader>te"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    -- ["<leader>tt"] = { "<cmd> tabNext <CR>", "[Tab] Nex[T]" },
    -- ["<leader>tq"] = { "<cmd> tabc <CR>", "[T]ab [q]uit" },

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
    ['<C-w>"'] = { "<cmd> split <CR>", "Split window horizontally" },
    ["<C-w>v"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>s"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>k"] = { "", "" },

    -- close buffer + hide terminal buffer
    ["<leader>q"] = {
      require("custom.buffer_utils").smart_close_buffer,
      "Close buffer",
    },
    ["<C-w><C-q>"] = {
      require("custom.buffer_utils").smart_close_window,
      "Smart close window",
    },
    ["<C-w>q"] = {
      require("custom.buffer_utils").smart_close_window,
      "Smart close window",
    },
    ["<leader>bh"] = {
      require("custom.buffer_utils").close_hidden_buffers,
      "Close hidden buffers",
    },
    -- navigator
    ["<C-h>"] = {
      "<CMD> NavigatorLeft <CR>",
      "Navigator left",
    },
    ["<C-j>"] = {
      "<CMD> NavigatorDown <CR>",
      "Navigator down",
    },
    ["<C-k>"] = {
      "<CMD> NavigatorUp <CR>",
      "Navigator up",
    },
    ["<C-l>"] = {
      "<CMD> NavigatorRight <CR>",
      "Navigator right",
    },
  },

  i = {
    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },
  },

  v = {
    ["<A-down>"] = { ":m '>+1<CR>gv=gv", "Move lines down" },
    ["<A-up>"] = { ":m '<-2<CR>gv=gv", "Move lines up" },
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
    ["<leader>ef"] = {
      function()
        -- find file path, change if outside the cwd
        local dir = vim.fn.expand "%:p:h"
        local curr_cwd = vim.fn.getcwd()
        local cwd = vim.startswith(dir, curr_cwd) and curr_cwd or dir

        local api = require "nvim-tree.api"
        api.tree.change_root(cwd)
        api.tree.find_file {
          focus = true,
          update_root = false,
        }
      end,
      "Nvimtree [f]ind file",
    },

    ["<C-0>"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  v = {
    ["<leader>fw"] = {
      function()
        require("telescope-live-grep-args.shortcuts").grep_visual_selection()
      end,
      "Live grep",
    },
  },
  n = {
    ["<leader>fp"] = {
      function()
        require("telescope").extensions.smart_open.smart_open {
          prompt_title = require("custom.path_utils").normalize_to_home(vim.fn.getcwd()),
          cwd = vim.fn.getcwd(),
          cwd_only = true,
        }
      end,
      "Find smart o[p]en",
    },
    ["<C-P>"] = {
      function()
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
    ["<leader>fo"] = { "<cmd> Telescope oldfiles hidden=true <CR>", "Find oldfiles" },
    ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>ff"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    ["<leader>fi"] = { "<cmd> Telescope import <CR>", "Find [i]mport" },
    ["<leader>fr"] = { "<cmd> Telescope resume <CR>", "[r]esume picker" },
    ["<leader>fu"] = { "<cmd> Telescope undo <CR>", "[U]ndo tree" },
    ["<leader>fd"] = {
      "<cmd> Telescope lsp_document_symbols follow=true no_ignore=true hidden=true <CR>",
      "Find all",
    },
    ["<leader>fw"] = { "<cmd> Telescope live_grep_args <CR>", "Live grep" },
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
        require("auto-session.session-lens").search_session {
          layout_strategy = "vertical",
          layout_config = { prompt_position = "top", width = 0.3, height = 0.4 },
          previewer = false,
        }
        -- require("telescope").load_extension "possession"
        -- require("telescope").extensions.possession.list()
      end,
      "Find sessions",
    },
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

M.autosession = {
  plugin = true,

  n = {
    ["<leader>ss"] = {
      function()
        vim.cmd [[ SessionSave ]]
      end,
      "Session [s]ave",
    },
  },
}

-- git things
M.gitsigns = {
  plugin = true,
  --
  n = {
    -- Actions
    ["<leader>ghr"] = {
      function()
        require("gitsigns").reset_hunk()
      end,
      "Git [h]unk [r]eset",
    },
    ["<leader>ghp"] = {
      function()
        require("gitsigns").preview_hunk()
      end,
      "Git [h]unk [p]review",
    },
    ["[h"] = {
      function()
        require("gitsigns").prev_hunk()
      end,
      "Prev hunk",
    },
    ["]h"] = {
      function()
        require("gitsigns").next_hunk()
      end,
      "Next hunk",
    },

    ["<leader>gf"] = { "<cmd> Telescope git_bcommits <CR>", "Git [f]ile history (telescope)" },
    ["<leader>gc"] = { "<cmd> Telescope git_commits <CR>", "Git [c]ommits (telescope)" },
    ["<leader>gs"] = { "<cmd> Telescope git_status <CR>", "Git [s]tatus (telescope)" },
    ["<leader>gz"] = {
      function()
        vim.cmd "Gitsigns toggle_signs"
      end,
      "[G]itsigns toggle [z]enmode",
    },
    ["<leader>gt"] = {
      function()
        require("gitsigns").toggle_deleted()
      end,
      "Git [t]oggle deleted",
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

-- vim.keymap.set('n', '<leader>S', '<cmd>lua require("spectre").toggle()<CR>', {
--     desc = "Toggle Spectre"
-- })
-- vim.keymap.set('n', '<leader>sw', '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
--     desc = "Search current word"
-- })
-- vim.keymap.set('v', '<leader>sw', '<esc><cmd>lua require("spectre").open_visual()<CR>', {
--     desc = "Search current word"
-- })
-- vim.keymap.set('n', '<leader>sp', '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
--     desc = "Search on current file"
-- })
M.spectre = {
  plugin = true,

  v = {
    ["<leader>rw"] = {
      function()
        local _, ls, cs = unpack(vim.fn.getpos "v")
        local _, le, ce = unpack(vim.fn.getpos ".")
        local visual = vim.api.nvim_buf_get_text(0, ls - 1, cs - 1, le - 1, ce, {})
        local text = visual[1] or ""
        require("spectre").open_visual { search_text = text }
      end,
      "Find+Replace [w]ord",
    },
  },
  n = {
    ["<leader>rf"] = {
      function()
        require("spectre").open_file_search { select_word = true }
      end,
      "Find+Replace [f]ile",
    },
    ["<leader>rw"] = {
      function()
        require("spectre").open_visual { select_word = true }
      end,
      "Find+Replace [w]ord",
    },
    ["<leader>ra"] = {
      function()
        require("spectre").toggle()
      end,
      "Find+Replace [a]ll",
    },
  },
}

M.undotree = {
  plugin = true,

  n = {
    ["<leader>eu"] = {
      function()
        vim.cmd [[ UndotreeShow ]]
        vim.cmd [[ UndotreeFocus ]]
        vim.cmd [[ NvimTreeClose ]]
      end,
      "[U]ndotree",
    },
  },
}

return M
