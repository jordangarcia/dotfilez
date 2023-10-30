local config = function()
  local N = require "multicursors.normal_mode"

  require("multicursors").setup {
    generate_hints = {
      normal = false,
      insert = true,
      extend = true,
    },
    normal_keys = {
      ["n"] = { method = N.find_next, opts = { desc = "Find next" } },
      ["N"] = { method = N.skip_find_next, opts = { desc = "Skip next" } },
      ["b"] = { method = N.skip_find_prev, opts = { desc = "Find prev" } },
    },
  }

  vim.api.nvim_set_hl(0, "MultiCursor", { bg = "#FFD700" })
  vim.api.nvim_set_hl(0, "MultiCursorMain", { bg = "#FFD700" })
  require("core.utils").load_mappings "multicursors"
end

return config
