local options = {
  defaults = {
    mappings = {
      n = {
        ["<c-x>"] = require("telescope.actions").delete_buffer,
        ["q"] = require("telescope.actions").close,
        ["<C-q>"] = require("telescope.actions").close,
        ["<C-s>"] = "select_vertical",
        ["<C-p>"] = false,
        ["<C-S-p>"] = false,
        ["<C-l>"] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist,
      },
      i = {
        ["<C-n>"] = false,
        ["<C-p>"] = false,
        ["<C-S-p>"] = false,
        ["<c-x>"] = require("telescope.actions").delete_buffer,
        ["<C-q>"] = require("telescope.actions").close,
        ["<C-l>"] = require('telescope.actions').send_selected_to_qflist + require('telescope.actions').open_qflist,
        -- ["<C-r>"] = "cycle_history_prev",
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
        ["<C-s>"] = "select_vertical",
        ["<C-o>"] = "select_default",
      },
    },
  }
}

return options
