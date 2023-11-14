return {
  "mbbill/undotree",
  event = "VeryLazy",
  keys = {
    {
      "<leader>eu",
      function()
        vim.cmd [[ UndotreeShow ]]
        vim.cmd [[ UndotreeFocus ]]
        vim.cmd [[ NvimTreeClose ]]
      end,
      desc = "[U]ndotree",
      mode = "n",
    },
  },
}
