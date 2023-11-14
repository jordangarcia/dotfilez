return {
  {
    "numToStr/Navigator.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("Navigator").setup {
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
