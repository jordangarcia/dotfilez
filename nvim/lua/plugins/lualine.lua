local palette = require("core.highlights").palette
local function hello()
  return [[hello world]]
end

local function visual_multi()
  local result = vim.api.nvim_call_function("VMInfos", {})
  if result.current then
    return "VM: " .. vim.inspect(result.patterns[1]) .. " " .. result.current .. "/" .. result.total
  end
  return ""
end

local function cwd()
  return require("custom.path_utils").normalize_to_home(vim.fn.getcwd())
end

local function recording()
  local recording_register = vim.fn.reg_recording()
  if recording_register == "" then
    return ""
  else
    return "Recording @" .. recording_register
  end
end

local function first(...)
  local args = { ... }
  return function()
    for _, v in ipairs(args) do
      local result = v()
      if result ~= "" then
        return result
      end
    end
  end
end

local function lsp_status()
  local status, result = pcall(function(...)
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = {}
    if rawget(vim, "lsp") then
      for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.attached_buffers[bufnr] and client.name ~= "null-ls" then
          table.insert(clients, client.name)
        end
      end
      if #clients == 0 then
        return ""
      end
      local str = table.concat(clients, " ")
      return "  " .. str
    end
  end)
  if not status then
    return ""
  end
  return result
end

---@type LazyPluginSpec
--
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  config = function()
    require("lualine").setup {
      options = {
        theme = "base16",
      },
      sections = {
        lualine_a = { first(recording, visual_multi, cwd) },
        lualine_b = {
          "branch",
          {
            "diagnostics",
            sections = { "error", "warn" },
          },
        },
        lualine_c = { "filename" },
        lualine_x = { "filetype" },
        lualine_y = { lsp_status },
        lualine_z = { "location", "searchcount" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      extensions = { "fzf" },
    }
  end,
}
