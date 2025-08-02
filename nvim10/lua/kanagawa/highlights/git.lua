-- local c = require("kanagawa.color")
local M = {}

---@param colors KanagawaColors
---@param config? KanagawaConfig
function M.setup(colors, config)
  local theme = colors.theme
  config = config or require("kanagawa").config
  return {
    -- Git commit highlights
    gitcommitOverflow = { fg = "#d8616b" },
    gitcommitSummary = { fg = "#98bb6c" },
    gitcommitComment = { fg = "#363646" },
    gitcommitUntracked = { fg = "#363646" },
    gitcommitDiscarded = { fg = "#363646" },
    gitcommitSelected = { fg = "#363646" },
    gitcommitHeader = { fg = "#9c86bf" },
    gitcommitSelectedType = { fg = "#7e9cd8" },
    gitcommitUnmergedType = { fg = "#7e9cd8" },
    gitcommitDiscardedType = { fg = "#7e9cd8" },
    gitcommitBranch = {
      fg = "#ffa066",
      bold = true,
    },
    gitcommitUntrackedFile = { fg = "#dca561" },
    gitcommitUnmergedFile = {
      fg = "#d8616b",
      bold = true,
    },
    gitcommitDiscardedFile = {
      fg = "#d8616b",
      bold = true,
    },
    gitcommitSelectedFile = {
      fg = "#98bb6c",
      bold = true,
    },
  }
end

return M
