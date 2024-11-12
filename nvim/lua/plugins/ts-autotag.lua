return {
  "windwp/nvim-ts-autotag",
  enabled = false,
  event = "VeryLazy",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup {
      autotag = {
        enable = true,
        enable_rename = true,
        enable_close = true,
        enable_close_on_slash = false,
      },
    }
  end,
}
