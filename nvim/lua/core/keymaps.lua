local merge_tb = vim.tbl_deep_extend

local function set_keymap_tbl(section_values, mapping_opt)
  for mode, mode_values in pairs(section_values) do
    local default_opts = merge_tb("force", { mode = mode }, mapping_opt or {})
    for keybind, mapping_info in pairs(mode_values) do
      local exists = vim.api.nvim_get_keymap(mode)[keybind]
      if type(mapping_info) == "string" then
        if exists then
          vim.api.nvim_set_keymap(mode, keybind, "<Nop>", { silent = true })
        end
      else
        -- merge default + user opts
        local opts = merge_tb("force", default_opts, mapping_info.opts or {})
        mapping_info.opts, opts.mode = nil, nil
        opts.desc = mapping_info[2]
        vim.keymap.set({ mode }, keybind, mapping_info[1], opts)
      end
    end
  end
end

-- disable all nvchad mappings
set_keymap_tbl {
  -- lspconfig
  n = {
    ["gD"] = "",
    ["gd"] = "",
    ["K"] = "",
    -- ["j"] = "",
    -- ["k"] = "",
    ["gi"] = "",
    ["<leader>cc"] = "",
    ["<c-r>"] = "",
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

set_keymap_tbl {
  n = {
    -- -- wrap shit
    -- ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    -- ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- disable stuff
    -- scrolling
    ["n"] = { "nzzzv" },
    ["N"] = { "Nzzzv" },
    ["<C-o>"] = { "<C-o>zz" },
    ["<C-i>"] = { "<C-i>zz" },

    ["<S-i>"] = {
      function()
        vim.cmd [[ NoiceDisable ]]
        vim.cmd [[ Inspect ]]

        vim.defer_fn(function()
          vim.cmd [[ NoiceEnable ]]
        end, 1000)
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

    ["<leader>yt"] = {
      function()
        vim.cmd [[ let @+ = "yarn test:watch -- " . expand('%') ]]
      end,
      "[Y]ank [t]est command",
    },

    ["<leader>yr"] = {
      function()
        vim.cmd [[ let @+ = "npx tsx " . expand('%') ]]
      end,
      "[Y]ank [r]un file",
    },

    ["<leader>yp"] = {
      function()
        vim.cmd [[ let @+ = "PYTHONPATH=src pdm run python " . expand('%') ]]
      end,
      "[Y]ank [p]ython run file",
    },

    ["<leader>ys"] = {
      function()
        local filename = vim.fn.expand "%:t"
        local filepart = filename:match "(.+)%.prompt%.tsx$"
        if filepart then
          vim.fn.setreg("+", 'yarn squidward dev --prompt "' .. filepart .. '"')
        else
          vim.notify("Not a .prompt.tsx file", vim.log.levels.WARN)
        end
      end,
      "[Y]ank -> [S]quidward",
    },

    ["<leader>yc"] = {
      function()
        vim.cmd [[ %y+ ]]
      end,
      "[Y]ank entire file [c]ontents",
    },

    -- scrolling
    -- ["<leader><tab><tab>"] = { "<cmd> tabNext <CR>", "[Tab] Next]" },
    -- ["<leader><tab>n"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    -- ["<leader><tab>p"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    -- ["<leader><tab>e"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    -- ["<leader><tab>t"] = { "<cmd> tabNext <CR>", "[Tab] Nex[T]" },
    -- ["<leader><tab>q"] = { "<cmd> tabc <CR>", "[T]ab [q]uit" },
    -- ["<leader>tn"] = { "<cmd> tabNext <CR>", "[T]ab [N]ext" },
    -- ["<leader>tp"] = { "<cmd> tabprevious <CR>", "[T]ab [P]rev" },
    -- ["<leader>te"] = { "<cmd> tabe <CR>", "[Tab] Creat[E]" },
    -- ["<leader>tt"] = { "<cmd> tabNext <CR>", "[Tab] Nex[T]" },
    -- ["<leader>tq"] = { "<cmd> tabc <CR>", "[T]ab [q]uit" },

    -- splitting
    ["<leader>v"] = { "<CMD> vsplit +enew <CR>", "v pslit" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    ["<C-Left>"] = { "<CMD> vertical resize -12 <CR>", "Decrease vert size", opts = { silent = true } },
    ["<C-Right>"] = { "<CMD> vertical resize +12 <CR>", "Increase vert size", opts = { silent = true } },
    ["<C-Up>"] = { "<CMD> horizontal resize +6 <CR>", "Increase horiz size", opts = { silent = true } },
    ["<C-Down>"] = { "<CMD> horizontal resize -6 <CR>", "Descrease horiz size", opts = { silent = true } },

    -- Quitting
    ["<c-q><c-q>"] = { "<cmd> qa! <CR>", "Force [q]uit" },
    ["<c-q><c-w>"] = { "<cmd> wqa! <CR>", "Force [q]uit and [w]rite" },

    -- window things
    ['<C-w>"'] = { "<cmd> split <CR>", "Split window horizontally" },
    ["<C-w>v"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>s"] = { "<cmd> vsplit <CR>", "Split window vertically" },
    ["<C-w>k"] = { "", "" },

    ["<leader>1"] = {
      "<CMD>tabn 1<CR>",
      "Buffer 1",
    },
    ["<leader>2"] = {
      "<CMD>tabn 2<CR>",
      "Buffer 2",
    },
    ["<leader>3"] = {
      "<CMD>tabn 3<CR>",
      "Buffer 3",
    },
    ["<leader>4"] = {
      "<CMD>tabn 4<CR>",
      "Buffer 4",
    },
    ["<leader>5"] = {
      "<CMD>tabn 5<CR>",
      "Buffer 5",
    },
    ["<leader>6"] = {
      "<CMD>tabn 6<CR>",
      "Buffer 6",
    },
    ["<leader>q"] = {
      require("custom.buffer_utils").smart_close_window,
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
    ["<leader>uh"] = {
      "<cmd> NoiceHistory <CR>",
      "Noice [h]istory",
    },
    ["<leader>um"] = {
      "<cmd> messages <CR>",
      "[m]essage history",
    },
    ["<leader>ba"] = {
      function()
        require("custom.buffer_utils").toggle_buffer_pin()
      end,
      "Pin buffer",
    },
    ["<leader>bd"] = {
      function()
        vim.cmd [[ bdelete ]]
      end,
      "Buffer [s]ource",
    },
    ["<leader>bl"] = {
      function()
        vim.notify("Buffer info\n" .. vim.inspect(require("custom.buffer_utils").ls()))
      end,
      "Buffer info",
    },
    ["<leader>bi"] = {
      function()
        local buf = vim.api.nvim_get_current_buf()
        -- local is_hidden = not vim.tbl_contains(non_hidden_buffer, buf)
        local loaded = vim.api.nvim_buf_is_loaded(buf)
        local listed = vim.api.nvim_buf_get_option(buf, "buflisted")
        local name = vim.api.nvim_buf_get_name(buf) -- Get the full path of the buffer
        local modified = vim.api.nvim_buf_get_option(buf, "modified") -- Check if the buffer has been modified
        vim.notify(
          "Buffer info\n"
            .. "\nid: "
            .. buf
            .. "\nname: "
            .. name
            .. "\nfiletype: "
            .. vim.api.nvim_buf_get_option(buf, "filetype")
            .. "\nlisted: "
            .. vim.inspect(listed)
            -- .. "\nhidden: "
            -- .. vim.inspect(is_hidden)
            .. "\nloaded: "
            .. vim.inspect(loaded)
        )
      end,
      "Buffer info",
    },
    ["<leader>bs"] = {
      "<CMD> source % <CR>",
      "Buffer [s]ource",
    },
    ["<leader>bh"] = {
      function()
        require("custom.buffer_utils").close_hidden_buffers()
      end,
      "Close hidden buffers",
    },
    -- cycle through buffers
    ["<S-l>"] = {
      function()
        vim.cmd [[ tabnext ]]
        -- require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },
    --
    ["<S-h>"] = {
      function()
        vim.cmd [[ tabprev ]]
        -- require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },
    -- TODO figure out bnext/prev
    ["[b"] = {
      function()
        vim.cmd [[ bprev ]]
        -- require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },
    ["]b"] = {
      function()
        vim.cmd [[ bnext ]]
        -- require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto next buffer",
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
    ["<leader>lwa"] = {
      function()
        vim.lsp.buf.add_workspace_folder()
      end,
      "Add workspace folder",
    },

    ["<leader>xf"] = {
      function()
        vim.cmd [[ source % ]]
        local file = vim.fn.expand "%"
        vim.notify("sourcing: " .. file)
      end,
      "Source [f]ile",
    },

    ["<leader>lwr"] = {
      function()
        vim.lsp.buf.remove_workspace_folder()
      end,
      "Remove workspace folder",
    },

    ["<leader>lwl"] = {
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      "List workspace folders",
    },
    ["<leader>lr"] = { "<cmd> LspRestart <CR>", "Lsp [r]estart" },
    ["<S-Tab>"] = { "<<", "Unindent" },
  },

  i = {
    -- save
    ["<C-s>"] = { "<esc> <cmd> w <CR>", "Save file" },
    ["<C-p>"] = { "<Nop>", "No-op" },
    ["<C-n>"] = { "<Nop>", "No-op" },
    ["<c-q><c-q>"] = { "<esc> <cmd> qa! <CR>", "Force [q]uit" },
    ["<c-q><c-w>"] = { "<esc> <cmd> wqa! <CR>", "Force [q]uit and [w]rite" },
    ["<S-Tab>"] = { "<C-d>", "Unindent" },
  },

  v = {
    ["<A-down>"] = { ":m '>+1<CR>gv=gv", "Move lines down" },
    ["<A-up>"] = { ":m '<-2<CR>gv=gv", "Move lines up" },
    ["<"] = { "<gv", "Indent line" },
    [">"] = { ">gv", "Indent line" },
    ["<S-Tab>"] = { "<gv", "Unindent" },

    ["<leader>xn"] = {
      function()
        -- run !node over selection range
        vim.cmd "normal! :!node <CR>"
        -- vim.cmd "!node"
        vim.notify "executing in node"
      end,
      "E[x]ecute [n]ode",
    },
  },

  x = {
    -- ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    -- ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },
  },
}
