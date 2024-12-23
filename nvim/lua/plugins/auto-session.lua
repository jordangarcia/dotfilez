return {
  "rmagatti/auto-session",
  lazy = false,
  keys = {
    {
      "<leader>sr",
      function()
        -- set mark to come back to
        vim.cmd [[ normal mR ]]
        vim.cmd [[ SessionDelete ]]
        vim.cmd [[ SessionSave ]]
        vim.cmd [[ silent! NvimTreeOpen ]]
        vim.cmd [[ winc = ]]
        -- go back to mark
        vim.cmd [[ normal 'R ]]
      end,
      desc = "Session [r]efresh",
      mode = "n",
    },
    {
      "<leader>sd",
      function()
        vim.cmd [[ SessionDelete ]]
      end,
      desc = "Session [d]elete",
      mode = "n",
    },
    {
      "<leader>ss",
      function()
        vim.cmd [[ SessionSave ]]
      end,
      desc = "Session [s]ave",
      mode = "n",
    },
  },
  opts = function()
    local buffer_utils = require "custom.buffer_utils"

    local function restore_nvim_tree()
      local nvimtree = require "nvim-tree.api"
      nvimtree.tree.open()
    end

    local function close_edgy()
      require("edgy").close()
    end

    local function close_nvim_tree()
      local nvimtree = require "nvim-tree.api"
      nvimtree.tree.close()
    end

    local cleanup_buffers = buffer_utils.close_buffers(function(data)
      local name = data.name
      return data.filetype == "help"
        or data.filetype == "undotree"
        or data.filetype == "noice"
        or string.find(name, "fugitive://")
        or string.find(name, "private/var/folders")
    end)

    return {
      log_level = "error",
      auto_session_suppress_dirs = { "~/", "~/code", "~/Downloads", "/" },

      post_restore_cmds = {
        -- restore_nvim_tree,
        -- "winc l",
        -- for some reason the first buffer doesnt start lsp
        -- "silent! LspStart",
        -- "winc =",
      },
      pre_save_cmds = {
        close_edgy,
        close_nvim_tree,
        cleanup_buffers,
      },
      auto_session_allowed_dirs = {
        "~/code/*",
        "~/.config/*",
        "~/code/dotfilez/nvim",
        "~/code/gamma/packages/*",
        "~/code/requestnow/*",
        "~/code/*/packages/*",
      },
      session_lens = {
        -- If load_on_setup is set to false, one needs to eventually call `require("auto-session").setup_session_lens()` if they want to use session-lens.
        buftypes_to_ignore = {}, -- list of buffer types what should not be deleted from current session
        load_on_setup = false,
        -- theme_conf = { border = true },
        previewer = false,
      },
    }
  end,
  config = function(_, opts)
    -- check env DISABLE_AUTO_SESSION
    local override = {}
    if os.getenv "DISABLE_AUTO_SESSION" == "1" then
      override.auto_session_enabled = false
      return
    end

    require("auto-session").setup(vim.tbl_deep_extend("force", opts, override))
  end,
}
