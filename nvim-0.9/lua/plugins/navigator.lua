return {
  {
    "numToStr/Navigator.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      local ok, wezterm = pcall(function()
        return require("Navigator.mux.wezterm"):new()
      end)
      require("Navigator").setup {
        mux = ok and wezterm or "auto",
        -- Disable navigation when the current mux pane is zoomed in
        disable_on_zoom = true,
      }
    end,
  },

  {
    "knubie/vim-kitty-navigator",
    enabled = false,
    lazy = false,
  },
}
