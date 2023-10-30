local M = {}

local builtin = require "telescope.builtin"

-- We cache the results of "git rev-parse"
-- Process creation is expensive in Windows, so this reduces latency
local is_inside_work_tree = {}

M.project_files = function()
  local opts = {} -- define here if you want to define something

  local cwd = vim.fn.getcwd()
  if is_inside_work_tree[cwd] == nil then
    vim.fn.system "git rev-parse --is-inside-work-tree"
    is_inside_work_tree[cwd] = vim.v.shell_error == 0
  end

  if is_inside_work_tree[cwd] then
    builtin.git_files {
      use_git_root = false,
      show_untracked = true,
    }
  else
    builtin.find_files {}
  end
end

M.options = {
  defaults = {
    mappings = {
      n = {
        ["<c-x>"] = require("telescope.actions").delete_buffer,
        ["q"] = require("telescope.actions").close,
        ["<C-q>"] = require("telescope.actions").close,
        ["<C-s>"] = "select_vertical",
        ["<C-p>"] = false,
        ["<C-S-p>"] = false,
        ["<C-l>"] = require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist,
      },
      i = {
        ["<C-n>"] = false,
        ["<C-p>"] = false,
        ["<C-S-p>"] = false,
        ["<c-x>"] = require("telescope.actions").delete_buffer,
        ["<C-q>"] = require("telescope.actions").close,
        ["<C-l>"] = require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist,
        -- ["<C-r>"] = "cycle_history_prev",
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
        ["<C-s>"] = "select_vertical",
        ["<C-o>"] = "select_default",
      },
    },
  },
  extensions_list = { "cder" },
  extensions = {
    cder = {
      dir_command = {
        "fd",
        "--type=d",
        "--exclude=node_modules",
        "--hidden",
        ".git$",
        os.getenv "HOME" .. "/code/",
        "|",
        [[ sed 's/\/.git\///']],
      },
      mappings = {
        default = function(directory)
          local val = string.gsub(directory, ".git", "")
          vim.cmd.cd(val)
        end,
      },
    },
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
}

return M
