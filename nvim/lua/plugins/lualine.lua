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

-- them colors
local colors = {
  bg = "#282a2e",
  alt_bg = "#373b41",
  dark_fg = "#969896",
  fg = "#b4b7b4",
  light_fg = "#c5c8c6",
  normal = "#81a2be",
  insert = "#b5bd68",
  visual = "#b294bb",
  replace = "#de935f",
}
local theme = {
  normal = {
    a = { fg = colors.bg, bg = colors.normal },
    b = { fg = colors.light_fg, bg = colors.alt_bg },
    c = { fg = colors.fg, bg = colors.bg },
  },
  replace = {
    a = { fg = colors.bg, bg = colors.replace },
    b = { fg = colors.light_fg, bg = colors.alt_bg },
  },
  insert = {
    a = { fg = colors.bg, bg = colors.insert },
    b = { fg = colors.light_fg, bg = colors.alt_bg },
  },
  visual = {
    a = { fg = colors.bg, bg = colors.visual },
    b = { fg = colors.light_fg, bg = colors.alt_bg },
  },
  inactive = {
    a = { fg = colors.dark_fg, bg = colors.bg },
    b = { fg = colors.dark_fg, bg = colors.bg },
    c = { fg = colors.dark_fg, bg = colors.bg },
  },
}

theme.command = theme.normal
theme.terminal = theme.insert

---@type LazyPluginSpec
return {
  "nvim-lualine/lualine.nvim",
  lazy = true,
  event = "UIEnter",
  config = function()
    require("lualine").setup {
      options = {
        theme = theme,
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
