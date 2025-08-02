return {
  cmd = { 'ruff', 'server', '--preview' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
  settings = {
    -- Server settings will be configured by the ruff server
  },
}