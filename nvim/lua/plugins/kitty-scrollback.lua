return {
  "mikesmithgh/kitty-scrollback.nvim",
  enabled = true,
  lazy = true,
  cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
  event = { "User KittyScrollbackLaunch" },
  config = function()
    require("kitty-scrollback").setup {
      minimal = {
        status_window = {
          enabled = false,
        },
        callbacks = {
          after_ready = function()
            vim.opt.number = false
            vim.opt.relativenumber = false
            vim.opt.signcolumn = "no"
            vim.opt.laststatus = 0
            vim.opt.showtabline = 0
            vim.opt.winbar = nil
            vim.opt.ruler = false
            vim.opt.statuscolumn = ""
            vim.opt.scrolloff = 999
          end,
        },
      },
    }
  end,
}
