---@type LazyPluginSpec
return {
  "chrisgrieser/nvim-early-retirement",
  opts = {
    -- If a buffer has been inactive for this many minutes, close it.
    retirementAgeMins = 5,

    -- Filetypes to ignore.
    ignoredFiletypes = {},

    -- Ignore files matching this lua pattern; empty string disables this setting.
    ignoreFilenamePattern = "",

    -- Will not close the alternate file.
    ignoreAltFile = true,

    -- Minimum number of open buffers for auto-closing to become active. E.g.,
    -- by setting this to 4, no auto-closing will take place when you have 3
    -- or fewer open buffers. Note that this plugin never closes the currently
    -- active buffer, so a number < 2 will effectively disable this setting.
    minimumBufferNum = 1,
  },
  config = true,
  event = "VeryLazy",
  -- lazy = false,
}
