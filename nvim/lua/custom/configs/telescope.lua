-- local action_state = require "telescope.actions.state"
-- local z_utils = require "telescope._extensions.zoxide.utils"

local options = {
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
        ["<C-S-P>"] = function()
          require("telescope").extensions.harpoon.list_marks()
        end,
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
        ["<C-S-P>"] = function()
          require("telescope").extensions.harpoon.list_marks()
        end,
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
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    zoxide = {
      prompt_title = "zoxide",
      path_display = "smart",
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
            local builtin = require "telescope.builtin"
            builtin.find_files { cwd = selection.path }
          end,
        },
        ["<C-w>"] = {
          keepinsert = false,
          action = function(selection)
            local builtin = require "telescope.builtin"
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

---@type NvPluginSpec
return {
  "nvim-telescope/telescope.nvim",
  cmd = "Telescope",
  dependencies = {
    {
      "nvim-telescope/telescope-live-grep-args.nvim",
      -- This will not install any breaking changes.
      -- For major updates, this must be adjusted manually.
      version = "^1.0.0",
    },
    "debugloop/telescope-undo.nvim",
    "jvgrootveld/telescope-zoxide",
    {
      "danielfalk/smart-open.nvim",
      dependencies = {
        "kkharji/sqlite.lua",
        -- Only required if using match_algorithm fzf
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        -- Optional.  If installed, native fzy will be used when match_algorithm is fzy
        { "nvim-telescope/telescope-fzy-native.nvim" },
      },
    },
    {
      "ThePrimeagen/harpoon",
      init = function(_)
        require("core.utils").load_mappings "harpoon"
      end,
      opts = require "custom.configs.harpoon",
      config = function() end,
    },
    {
      "prochri/telescope-all-recent.nvim",
      dependencies = { "kkharji/sqlite.lua" },
      config = function() end,
    },
  },
  opts = function()
    local opts = require "plugins.configs.telescope"
    return vim.tbl_deep_extend("force", opts, options)
  end,
  config = function(_, opts)
    dofile(vim.g.base46_cache .. "telescope")
    local telescope = require "telescope"
    telescope.setup(opts)

    local extensions = { "harpoon", "zoxide", "smart_open", "undo", "live_grep_args" }
    -- load extensions
    for _, ext in ipairs(extensions) do
      telescope.load_extension(ext)
    end

    -- load autosession
    require("auto-session").setup_session_lens()

    require("telescope-all-recent").setup {}
  end,
}
