local action_state = require "telescope.actions.state"
local z_utils = require "telescope._extensions.zoxide.utils"
local builtin = require "telescope.builtin"

local M = {}

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
    file_ignore_patterns = { "node_modules", "src/translations", "yarn.lock" },

    path_display = {
      shorten = {
        len = 3,
        exclude = { 1, 2, 3, -1, -2 },
      },
    },

    mappings = {
      n = {
        ["<c-x>"] = require("telescope.actions").delete_buffer,
        ["q"] = require("telescope.actions").close,
        ["<C-q>"] = require("telescope.actions").close,
        -- for some reason this does not work in insert mode
        ["<C-S-P>"] = require("telescope").extensions.harpoon.list_marks,
        ["<C-p>"] = function()
          require("telescope").extensions.smart_open.smart_open {
            cwd = vim.fn.getcwd(),
            cwd_only = true,
          }
        end,
        ["<C-s>"] = "select_vertical",
        ["<C-S-p>"] = false,
        ["<C-l>"] = require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist,
      },
      i = {
        ["<C-n>"] = false,
        ["<C-p>"] = function()
          require("telescope").extensions.smart_open.smart_open {
            cwd = vim.fn.getcwd(),
            cwd_only = true,
          }
        end,
        ["<C-S-P>"] = require("telescope").extensions.harpoon.list_marks,
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
  extensions_list = { "cder", "harpoon", "zoxide", smart_open },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    zoxide = {
      prompt_title = "zoxide",
      mappings = {
        default = {
          action = function(selection)
            vim.cmd.tcd(selection.path)
          end,
          after_action = function(selection)
            print("Directory tab working directory to " .. selection.path)
          end,
        },
        ["<C-s>"] = {},
        ["<C-v>"] = {},
        ["<C-e>"] = {},
        ["<C-b>"] = {},
        ["<C-f>"] = {
          keepinsert = true,
          action = function(selection)
            builtin.find_files { cwd = selection.path }
          end,
        },
        ["<C-w>"] = {
          keepinsert = false,
          action = function(selection)
            builtin.live_grep { cwd = selection.path }
          end,
        },
        ["<C-p>"] = {
          action = function(selection)
            require("telescope").extensions.smart_open.smart_open {
              prompt_title = require("custom.path_utils").normalize_to_home(selection.path),
              cwd = selection.path,
              cwd_only = true,
            }
          end,
          function() end,
          "Find smart open",
        },
        ["<C-t>"] = {},
      },
    },
  },
}

return M
