return {
  {
    "knubie/vim-kitty-navigator",
    lazy = false,
    init = function()
      -- core/keymaps.lua maps ctrl+h/j/k/l to core/rex_navigator.lua, which
      -- calls this plugin's KittyNavigate* commands outside Rex.
      vim.g.kitty_navigator_no_mappings = 1
    end,
  },
}
