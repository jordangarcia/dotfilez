local path_utils = require "custom.path_utils"

local function my_on_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  vim.keymap.set("n", "mc", api.fs.copy.node, opts "Copy")

  -- open
  vim.keymap.set("n", "<leader>fw", function(filename)
    local node = api.tree.get_node_under_cursor()
    local path = node.absolute_path

    if node.type == "directory" and path then
      local ppath = path_utils.normalize_to_home(path)
      require("telescope").extensions.live_grep_args.live_grep_args {
        prompt_title = "live_grep_args " .. ppath,
        cwd = path,
      }
    end
    -- print("grepping filename" .. vim.inspect(node))
    -- print("grepping filename" .. vim.inspect(node.absolute_path))
  end, opts "Grep here")

  vim.keymap.set("n", "<leader>fp", function(filename)
    local node = api.tree.get_node_under_cursor()
    local path = node.absolute_path

    if node.type == "directory" and path then
      local ppath = path_utils.normalize_to_home(path)
      require("telescope").extensions.smart_open.smart_open {
        prompt_title = "Find: " .. ppath,
        cwd = path,
        cwd_only = true,
      }
    end
    -- print("grepping filename" .. vim.inspect(node))
    -- print("grepping filename" .. vim.inspect(node.absolute_path))
  end, opts "Find here")

  vim.keymap.set("n", "o", api.node.open.edit, opts "Open")
  vim.keymap.set("n", "<CR>", api.node.open.edit, opts "Open")
  vim.keymap.set("n", "O", api.node.open.no_window_picker, opts "Open: No Window Picker")
  vim.keymap.set("n", "<C-v>", api.node.open.vertical, opts "Open: Vertical Split")
  vim.keymap.set("n", "s", api.node.open.vertical, opts "Open: Vertical Split")
  vim.keymap.set("n", "<C-x>", api.node.open.horizontal, opts "Open: Horizontal Split")
  vim.keymap.set("n", "<C-O>", api.node.run.system, opts "Run System")
  vim.keymap.set("n", "<C-t>", api.node.open.tab, opts "Open: New Tab")

  -- rename
  vim.keymap.set("n", "<C-r>", api.fs.rename_sub, opts "Rename: Omit Filename")
  vim.keymap.set("n", "re", api.fs.rename_basename, opts "Rename: Basename")
  vim.keymap.set("n", "rr", api.fs.rename, opts "Rename")
  vim.keymap.set("n", "mm", api.fs.rename_full, opts "Rename: Full Path")

  -- Nerdtree tings
  vim.keymap.set("n", "ma", api.fs.create, opts "Create")
  vim.keymap.set("n", "md", api.fs.remove, opts "Delete")
  vim.keymap.set("n", "mp", api.fs.paste, opts "Paste")
  vim.keymap.set("n", "mx", api.fs.cut, opts "Cut")

  -- create

  local function toggle_all()
    api.tree.toggle_hidden_filter()
    api.tree.toggle_gitignore_filter()
  end
  -- toggle showing
  vim.keymap.set("n", "B", api.tree.toggle_no_buffer_filter, opts "Toggle Filter: No Buffer")
  vim.keymap.set("n", "gc", api.tree.toggle_git_clean_filter, opts "Toggle Filter: Git Clean")
  vim.keymap.set("n", "I", toggle_all, opts "Toggle Filter: Dotfiles")
  vim.keymap.set("n", "tg", api.tree.toggle_gitignore_filter, opts "Toggle Filter: Git Ignore")
  vim.keymap.set("n", "td", api.tree.toggle_hidden_filter, opts "Toggle Filter: Dotfiles")
  vim.keymap.set("n", "U", api.tree.toggle_custom_filter, opts "Toggle Filter: Hidden")

  -- filtering
  vim.keymap.set("n", "F", api.live_filter.clear, opts "Clean Filter")
  vim.keymap.set("n", "f", api.live_filter.start, opts "Filter")
  vim.keymap.set("n", "R", api.tree.reload, opts "Refresh")
  -- navigating
  vim.keymap.set("n", "C", api.tree.change_root_to_node, opts "CD")
  vim.keymap.set("n", "u", api.tree.change_root_to_parent, opts "Up")
  vim.keymap.set("n", "P", api.node.navigate.parent, opts "Parent Directory")
  -- open/closing
  vim.keymap.set("n", "<BS>", api.node.navigate.parent_close, opts "Close Directory")
  vim.keymap.set("n", "E", api.tree.expand_all, opts "Expand All")
  vim.keymap.set("n", "W", api.tree.collapse_all, opts "Collapse")
  -- copying path
  vim.keymap.set("n", "ca", api.fs.copy.absolute_path, opts "Copy Absolute Path")
  vim.keymap.set("n", "cn", api.fs.copy.filename, opts "Copy Name")
  vim.keymap.set("n", "cp", api.fs.copy.relative_path, opts "Copy Relative Path")
  -- help
  vim.keymap.set("n", "?", api.tree.toggle_help, opts "Help")

  -- BEGIN_DEFAULT_ON_ATTACH
  -- vim.keymap.set("n", "<C-e>", api.node.open.replace_tree_buffer, opts "Open: In Place")
  vim.keymap.set("n", "<C-i>", api.node.show_info_popup, opts "Info")

  -- vim.keymap.set("n", "<Tab>", api.node.open.preview, opts "Open Preview")
  -- vim.keymap.set("n", ">", api.node.navigate.sibling.next, opts "Next Sibling")
  -- vim.keymap.set("n", "<", api.node.navigate.sibling.prev, opts "Previous Sibling")
  vim.keymap.set("n", ".", api.node.run.cmd, opts "Run Command")
  -- vim.keymap.set("n", "bd", api.marks.bulk.delete, opts "Delete Bookmarked")
  -- vim.keymap.set("n", "bt", api.marks.bulk.trash, opts "Trash Bookmarked")
  -- vim.keymap.set("n", "bmv", api.marks.bulk.move, opts "Move Bookmarked")
  -- vim.keymap.set("n", "[c", api.node.navigate.git.prev, opts "Prev Git")
  -- vim.keymap.set("n", "]c", api.node.navigate.git.next, opts "Next Git")
  -- vim.keymap.set("n", "D", api.fs.trash, opts "Trash")
  -- vim.keymap.set("n", "]e", api.node.navigate.diagnostics.next, opts "Next Diagnostic")
  -- vim.keymap.set("n", "[e", api.node.navigate.diagnostics.prev, opts "Prev Diagnostic")
  vim.keymap.set("n", "J", api.node.navigate.sibling.last, opts "Last Sibling")
  vim.keymap.set("n", "K", api.node.navigate.sibling.first, opts "First Sibling")
  -- vim.keymap.set("n", "m", api.marks.toggle, opts "Toggle Bookmark")

  -- vim.keymap.set("n", "q", api.tree.close, opts "Close")
  -- vim.keymap.set("n", "s", api.node.run.system, opts "Run System")
  -- vim.keymap.set("n", "S", api.tree.search_node, opts "Search")
  -- vim.keymap.set("n", "x", api.fs.cut, opts "Cut")
  -- vim.keymap.set("n", "<2-LeftMouse>", api.node.open.edit, opts "Open")
  -- vim.keymap.set("n", "<2-RightMouse>", api.tree.change_root_to_node, opts "CD")
  -- END_DEFAULT_ON_ATTACH
end

local options = {
  on_attach = my_on_attach,
  filters = {
    dotfiles = true,
    git_ignored = true,
    exclude = { vim.fn.stdpath "config" .. "/lua/custom" },
  },
  disable_netrw = true,
  hijack_netrw = true,
  hijack_cursor = true,
  hijack_unnamed_buffer_when_opening = false,
  sync_root_with_cwd = false,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    adaptive_size = false,
    side = "left",
    width = 30,
    preserve_window_proportions = true,
  },
  git = {
    enable = true,
    ignore = true,
  },
  filesystem_watchers = {
    enable = true,
    ignore_dirs = { "node_modules" },
  },
  actions = {
    -- change_dir = {
    --   restrict_above_cwd = true,
    --   global = true,
    -- },
    open_file = {
      resize_window = true,
    },
  },
  renderer = {
    root_folder_label = ":~:s?$?/",
    highlight_git = true,
    highlight_opened_files = "none",

    indent_markers = {
      enable = false,
    },

    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = false,
        git = false,
      },

      glyphs = {
        default = "󰈚",
        symlink = "",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
          symlink_open = "",
          arrow_open = "",
          arrow_closed = "",
        },
        git = {
          unstaged = "✗",
          staged = "✓",
          unmerged = "",
          renamed = "➜",
          untracked = "★",
          deleted = "",
          ignored = "◌",
        },
      },
    },
  },
}

return {
  "nvim-tree/nvim-tree.lua",
  cmd = { "NvimTreeToggle", "NvimTreeFocus" },
  keys = {
    {
      "<C-e>",
      "<cmd> NvimTreeToggle <CR>",
      desc = "Toggle nvimtree",
      mode = "n",
    },
    {
      "<leader>ef",
      function()
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
      desc = "Nvimtree [f]ind file",
      mode = "n",
    },
    {
      "<C-0>",
      "<cmd> NvimTreeFocus <CR>",
      desc = "Focus nvimtree",
      mode = "n",
    },
  },
  opts = options,
  config = function(_, opts)
    -- dofile(vim.g.base46_cache .. "nvimtree")
    require("nvim-tree").setup(opts)
  end,
}
