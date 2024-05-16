---@type LazyPluginSpec
return {
  -- TODO
  -- https://azamuddin.com/en/blog/050623-setting-up-copilot-on-nvchad
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        debounce = 75,
        keymap = {
          -- accept = "<C-l>",
          -- accept = "<C-l>",
          accept = "<C-l>",
          accept_word = false,
          accept_line = false,
          next = "<C-k>",
          prev = "<C-j>",
          dismiss = "<C-e>",
        },
      },
      filetypes = {
        lua = true,
        javascript = true,
        python = true,
        typescriptreact = true,
        typescript = true,
        json = true,
        yaml = true,
        html = true,
        css = true,
        ["*"] = true,
      },
      panel = { enabled = false },
    }
  end,
}
