local options = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "json",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "prisma",
    "graphql",
  },

  autotag = {
    enable = true,
  },

  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },
}

return options
