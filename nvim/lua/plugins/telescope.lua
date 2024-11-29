-- local action_state = require "telescope.actions.state"
-- local z_utils = require "telescope._extensions.zoxide.utils"

---@type LazyPluginSpec[]
return {

  {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope", "Easypick" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope-file-browser.nvim",
      "piersolenski/telescope-import.nvim",
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
        "prochri/telescope-all-recent.nvim",
        dependencies = { "kkharji/sqlite.lua" },
        config = function() end,
      },
    },
    keys = {
      {
        "<leader>fv",
        function()
          require("telescope.builtin").find_files {
            cwd = vim.fn.stdpath "config",
          }
        end,
        desc = "[v]im files",
        mode = "n",
      },

      {
        "<leader>fw",
        function()
          require("telescope-live-grep-args.shortcuts").grep_visual_selection()
        end,
        desc = "Live grep",
        mode = "x",
      },
      {
        "<leader>fp",
        function()
          require("telescope").extensions.smart_open.smart_open {
            prompt_title = require("custom.path_utils").normalize_to_home(vim.fn.getcwd()),
            cwd = vim.fn.getcwd(),
            cwd_only = true,
          }
        end,
        desc = "Find smart o[p]en",
        mode = "n",
      },
      {
        "<C-P>",
        function()
          require("telescope").extensions.smart_open.smart_open {
            prompt_title = require("custom.path_utils").normalize_to_home(vim.fn.getcwd()),
            cwd = vim.fn.getcwd(),
            cwd_only = true,
          }
        end,
        desc = "Find smart open",
        mode = "n",
      },
      {
        "<C-S-O>",
        function()
          require("telescope.builtin").builtin()
        end,
        desc = "Find builtins",
        mode = "n",
      },
      {
        "<C-b>",
        "<cmd> Telescope buffers show_all_buffers=false sort_mru=true cwd_only=true <CR>",
        desc = "Find buffers",
        mode = "n",
      },
      -- {
      --   "<C-t>",
      --   function()
      --     require("telescope.builtin").lsp_dynamic_workspace_symbols {
      --       sorter = require("telescope.sorters").get_substr_matcher(),
      --       -- ignore_symbols = { "property ", "variable" },
      --     }
      --   end,
      --   desc = "Find symbols",
      --   mode = "n",
      -- },
      {
        "<leader>fo",
        "<cmd> Telescope oldfiles hidden=true <CR>",
        desc = "Find oldfiles",
        mode = "n",
      },
      {
        "<leader>fa",
        "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>",
        desc = "Find all",
        mode = "n",
      },
      {
        "<leader>ff",
        "<cmd> Telescope find_files <CR>",
        desc = "Find files",
        mode = "n",
      },
      {
        "<leader>fi",
        "<cmd> Telescope import <CR>",
        desc = "Find [i]mport",
        mode = "n",
      },
      {
        "<leader>fr",
        "<cmd> Telescope resume <CR>",
        desc = "[r]esume picker",
        mode = "n",
      },
      {
        "<leader>fu",
        "<cmd> Telescope undo <CR>",
        desc = "[U]ndo tree",
        mode = "n",
      },
      {
        "<leader>fd",
        ":Telescope file_browser path=%:p:h select_buffer=true<CR>",
        desc = "File browser",
        mode = "n",
      },
      {
        "<leader>fw",
        "<cmd> Telescope live_grep_args <CR>",
        desc = "Live grep",
        mode = "n",
      },

      {
        "<leader>fe",
        function()
          require("telescope.builtin").live_grep {
            prompt_title = "live_grep buffers",
            grep_open_files = true,
          }
        end,
        desc = "Live grep op[e]n files",
        mode = "n",
      },
      {
        "<leader>fw",
        "<cmd> Telescope live_grep_args <CR>",
        desc = "Live grep",
        mode = "n",
      },
      {
        "<leader>fb",
        "<cmd> Telescope buffers <CR>",
        desc = "Find buffers",
        mode = "n",
      },
      {
        "<leader>fh",
        "<cmd> Telescope help_tags <CR>",
        desc = "Help page",
        mode = "n",
      },
      {
        "<leader>fz",
        function()
          require("telescope").extensions.zoxide.list {
            layout_strategy = "vertical",
            layout_config = { prompt_position = "top", width = 0.3, height = 0.4 },
          }
        end,
        desc = "Find [z]oxide",
        mode = "n",
      },
      {
        "<leader>fs",
        function()
          require("auto-session.session-lens").search_session {
            layout_strategy = "vertical",
            layout_config = { prompt_position = "top", width = 0.3, height = 0.4 },
            previewer = false,
          }
        end,
        desc = "Find sessions",
        mode = "n",
      },
    },

    opts = function()
      local actions = require "telescope.actions"
      return {
        defaults = {
          file_ignore_patterns = { "node_modules", "src/translations", "yarn.lock" },

          path_display = {
            shorten = {
              len = 3,
              exclude = { 1, 2, 3, -1, -2 },
            },
          },

          vimgrep_arguments = {
            "rg",
            "-L",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          prompt_prefix = "   ",
          selection_caret = "  ",
          entry_prefix = "  ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          file_sorter = require("telescope.sorters").get_fuzzy_file,
          generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
          -- winblend = 0,
          -- border = {},
          -- borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          -- color_devicons = true,
          set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
          -- Developer configurations: Not meant for general override
          buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
          mappings = {
            n = {
              ["<c-x>"] = require("telescope.actions").delete_buffer,
              -- remap close
              -- default binding in normal also  has `<esc>`
              ["q"] = require("telescope.actions").close,
              ["<C-q>"] = require("telescope.actions").close,
              -- disable default close
              ["<C-c>"] = false,
              ["<C-l>"] = require("telescope.actions").send_selected_to_qflist
                + require("telescope.actions").open_qflist,

              -- custom movements
              ["<C-p>"] = actions.preview_scrolling_up,
              ["<C-n>"] = actions.preview_scrolling_down,

              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,

              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-d>"] = actions.results_scrolling_down,
            },
            i = {
              -- remap close
              -- default binding in normal also  has `<esc>`
              ["q"] = false,
              ["<C-q>"] = require("telescope.actions").close,
              -- disable default close
              ["<C-c>"] = false,
              ["<c-x>"] = require("telescope.actions").delete_buffer,
              ["<C-l>"] = require("telescope.actions").send_selected_to_qflist
                + require("telescope.actions").open_qflist,
              -- ["<C-r>"] = "cycle_history_prev",
              -- custom movements
              ["<C-p>"] = actions.preview_scrolling_up,
              ["<C-n>"] = actions.preview_scrolling_down,

              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,

              ["<C-u>"] = actions.results_scrolling_up,
              ["<C-d>"] = actions.results_scrolling_down,
              -- ["<C-j>"] = "move_selection_next",
              -- ["<C-k>"] = "move_selection_previous",
              -- ["<C-s>"] = "select_vertical",
              -- ["<C-o>"] = "select_default",
            },
          },
        },
        pickers = {
          lsp_references = {
            initial_mode = "normal",
            show_line = false,
            layout_config = {
              width = function(_, max_columns, _)
                return math.min(max_columns, 200) -- Set max width to 120 characters
              end,
            },
          },
          lsp_type_definitions = {
            initial_mode = "normal",
            show_line = false,
            layout_config = {
              width = function(_, max_columns, _)
                return math.min(max_columns, 200) -- Set max width to 100 characters
              end,
            },
          },
          lsp_definitions = {
            initial_mode = "normal",
            show_line = false,
            layout_config = {
              width = function(_, max_columns, _)
                return math.min(max_columns, 200) -- Set max width to 100 characters
              end,
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
              ["<C-f>"] = {},
              ["<C-w>"] = {
                keepinsert = false,
                action = function(selection)
                  require("telescope").extensions.live_grep_args.live_grep_args {
                    prompt_title = "live_grep_args " .. require("custom.path_utils").normalize_to_home(selection.path),
                    cwd = selection.path,
                  }
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
    end,
    config = function(_, opts)
      -- dofile(vim.g.base46_cache .. "telescope")
      local telescope = require "telescope"
      telescope.setup(opts)

      local extensions = { "zoxide", "smart_open", "undo", "live_grep_args", "import", "file_browser" }
      -- load extensions
      for _, ext in ipairs(extensions) do
        telescope.load_extension(ext)
      end

      -- load autosession
      -- require("auto-session").setup_session_lens()
      require("telescope-all-recent").setup {}

      -- disable lexima in telescope prompt
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "TelescopePrompt",
        callback = function()
          vim.b.lexima_disabled = 1
        end,
      })
    end,
  },
}
