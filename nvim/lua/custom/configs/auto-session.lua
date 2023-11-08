local buffer_utils = require "custom.buffer_utils"
local function restore_nvim_tree()
  local nvimtree = require "nvim-tree.api"
  nvimtree.tree.open()
end

local function close_nvim_tree()
  local nvimtree = require "nvim-tree.api"
  nvimtree.tree.close()
end

return {
  log_level = "error",
  auto_session_suppress_dirs = { "~/", "~/code", "~/Downloads", "/" },
  post_restore_cmds = { restore_nvim_tree, "winc l", "winc =" },
  pre_save_cmds = {
    close_nvim_tree,
    buffer_utils.close_all_fugitive_blame_buffers,
    buffer_utils.close_all_fugitive_buffers,
  },
  session_lens = {
    -- If load_on_setup is set to false, one needs to eventually call `require("auto-session").setup_session_lens()` if they want to use session-lens.
    buftypes_to_ignore = {}, -- list of buffer types what should not be deleted from current session
    load_on_setup = false,
    -- theme_conf = { border = true },
    previewer = false,
  },
}
