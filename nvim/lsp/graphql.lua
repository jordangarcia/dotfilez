return {
  cmd = { 'graphql-lsp', 'server', '-m', 'stream' },
  filetypes = { 'graphql', 'gql', 'typescriptreact', 'javascriptreact' },
  root_markers = { 'package.json', '.graphqlrc', '.graphql.config.js' },
  settings = {},
}