return {
  "mg979/vim-visual-multi",
  event = "VeryLazy",
  init = function()
    vim.cmd [[
      let g:VM_set_statusline = 1
      let g:VM_maps = {}
      let g:VM_maps['Find Under']         = '<C-f>'
      let g:VM_maps['Find Subword Under'] = '<C-f>'
    ]]
  end,
}
