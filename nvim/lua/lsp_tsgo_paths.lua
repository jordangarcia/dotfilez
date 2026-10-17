-- Project roots served by tsgo. Each entry is both the match prefix and the LSP
-- root_dir, so a bun/yarn workspace root here keeps one server for every package.
local paths = {
  vim.fn.expand "~/code/gamma/packages/client",
  vim.fn.expand "~/code/3gamma/packages/client",
  -- bun workspace root; packages/* all resolve through the root tsconfig.json
  vim.fn.expand "~/code/gamma/agent",
}

local function root_for(bufname)
  for _, path in ipairs(paths) do
    local is_root = bufname == path
    local is_inside = bufname:sub(1, #path + 1) == path .. "/"

    if is_root or is_inside then
      return path
    end
  end

  return nil
end

return {
  paths = paths,
  root_for = root_for,
}
