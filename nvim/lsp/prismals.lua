return {
  cmd = { 'prisma-language-server', '--stdio' },
  filetypes = { 'prisma' },
  root_markers = { 'schema.prisma', 'package.json' },
  settings = {
    prisma = {
      prismaFmtBinPath = "",
    },
  },
}