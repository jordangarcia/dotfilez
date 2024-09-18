-- To find any highlight groups: "<cmd> Telescope highlights"
-- Each highlight group can take a table with variables fg, bg, bold, italic, etc
-- base30 variable names can also be used as colors

local M = {}

-- good var #DCD7BA
-- bad var  #C8C3A6
local palette = {
  -- bg shades
  sumiInk0 = "#16161D",
  sumiInk1 = "#181820",
  sumiInk2 = "#1a1a22",
  sumiInk3 = "#1F1F28",
  sumiInk4 = "#2A2A37",
  sumiInk5 = "#363646",
  sumiInk6 = "#54546D", --fg
  waveBlue1 = "#223249",
  waveBlue2 = "#2D4F67",
  waveAqua1 = "#6A9589",
  waveAqua2 = "#7AA89F", -- improve lightness: desaturated greenish Aqua
  springGreen = "#98BB6C",
  sakuraPink = "#D27E99",
  surimiOrange = "#FFA066",
  oniViolet2 = "#b8b4d0",
  springViolet2 = "#9CABCA",
  crystalBlue = "#7E9CD8",
  oniViolet = "#957FB8",
  katanaGray = "#717C7C",

  -- Diff and Git
  winterGreen = "#2B3328",
  winterYellow = "#49443C",
  winterRed = "#43242B",
  winterBlue = "#252535",
  autumnGreen = "#76946A",
  autumnRed = "#C34043",
  autumnYellow = "#DCA561",

  oldWhite = "#C8C093",
  fujiWhite = "#DCD7BA",
  fujiGray = "#727169",

  waveRed = "#E46876",
  springBlue = "#7FB4CA",
  peachRed = "#FF5D62",
  -- yellow
  boatYellow1 = "#938056",
  boatYellow2 = "#C0A36E",
  carpYellow = "#E6C384",
  samuraiRed = "#E82424",

  dragonBlue = "#658594",
  dragonGray2 = "#9e9b93",
  roninYellow = "#FF9E3B",
}

local base_30 = {
  white = "#DCD7BA",
  darker_black = "#191922",
  black = "#1F1F28", --  nvim bg
  black2 = "#25252e",
  one_bg = "#272730",
  one_bg2 = "#2f2f38",
  one_bg3 = "#363646",
  grey = "#43434c",
  grey_fg = "#4c4c55",
  grey_fg2 = "#53535c",
  light_grey = "#5c5c65",
  red = "#d8616b",
  baby_pink = "#D27E99",
  pink = "#c8748f",
  line = "#31313a", -- for lines like vertsplit
  green = "#98BB6C",
  vibrant_green = "#a3c677",
  nord_blue = "#7E9CD8",
  blue = "#7FB4CA",
  yellow = "#FF9E3B",
  sun = "#FFA066",
  purple = "#a48ec7",
  dark_purple = "#9c86bf",
  teal = "#7AA89F",
  orange = "#fa9b61",
  cyan = "#A3D4D5",
  statusline_bg = "#24242d",
  lightbg = "#33333c",
  pmenu_bg = "#a48ec7",
  folder_bg = "#7E9CD8",
}

M.base_16 = {
  base00 = "#1f1f28",
  base01 = "#2a2a37",
  base02 = "#223249",
  base03 = "#363646",
  base04 = "#4c4c55",
  base05 = "#c8c3a6",

  base06 = "#d2cdb0",
  base07 = "#DCD7BA",
  base08 = "#d8616b",
  base09 = "#ffa066",
  base0A = "#dca561",
  base0B = "#98bb6c",
  base0C = "#7fb4ca",
  base0D = "#7e9cd8",
  base0E = "#9c86bf",
  base0F = "#d8616b",
}

local diff = {
  add = palette.winterGreen,
  delete = palette.winterRed,
  change = palette.winterBlue,
  text = palette.winterYellow,
}
local diag = {
  ok = palette.springGreen,
  error = palette.samuraiRed,
  warning = palette.roninYellow,
  info = palette.dragonBlue,
  hint = palette.waveAqua1,
}
local syn = {
  string = palette.springGreen,
  variable = palette.fujiWhite,
  number = palette.sakuraPink,
  -- constant = palette.surimiOrange,
  --   base07 = kkk

  constant = palette.carpYellow,
  identifier = palette.carpYellow,
  parameter = palette.oniViolet2,
  fun = palette.crystalBlue,
  statement = palette.oniViolet,
  keyword = palette.oniViolet,
  operator = palette.boatYellow2,
  preproc = palette.springBlue, --lightBlue? deserves its own color
  type = palette.waveAqua2,
  regex = palette.boatYellow2,
  deprecated = palette.katanaGray,
  comment = palette.fujiGray,
  -- punct = palette.fujiGray,
  -- punct = palette.springViolet1,

  -- maybe springViolet2?
  punct = palette.dragonGray2,

  special1 = palette.springBlue,
  special2 = palette.waveRed,
  special3 = palette.peachRed,
}

local gutter_bg = palette.sumiInk4

---@type Base46HLGroupsList
M.override = {
  WinSeparator = { fg = palette.sumiInk4, bg = palette.sumiInk3 },
  Comment = {
    italic = true,
  },

  -- variables are white
  Variable = { fg = palette.fujiWhite },
  Include = { fg = palette.surimiOrange },
  Boolean = { fg = palette.surimiOrange, bold = true },
  Constant = { link = "Variable" },
  String = { fg = syn.string },
  Character = { link = "String" },
  Number = { fg = syn.number },
  Float = { link = "Number" },
  Identifier = { fg = syn.identifier },
  Function = { fg = syn.fun },
  Statement = { fg = syn.statement },
  Operator = { fg = syn.operator },
  Keyword = { fg = syn.keyword },
  Exception = { fg = syn.special2 },
  PreProc = { fg = syn.preproc },
  Type = { fg = syn.type },

  ["Label"] = {
    fg = palette.carpYellow,
  },

  ["@namespace"] = {
    fg = palette.carpYellow,
  },
  ["@constructor"] = {
    link = "Type",
    -- fg = palette.oniViolet,
  },
  ["Structure"] = {
    link = "Type",
  },
  ["@lsp.type.property"] = {},
  ["@field"] = {
    link = "@property",
  },
  ["@property"] = {
    fg = palette.carpYellow,
  },
  ["@variable"] = {
    link = "Variable",
  },
  ["@parameter"] = {
    link = "Variable",
  },
  ["@exception"] = {
    fg = palette.peachRed,
    bold = true,
  },
  ["@variable.builtin"] = {
    fg = palette.waveRed,
  },
  ["@constant.builtin"] = {
    fg = palette.springBlue,
  },
  ["@type.builtin"] = {
    fg = "teal",
  },
  ["@keyword.operator"] = {
    fg = palette.oniViolet,
  },
  ["@punctuation.delimiter"] = { fg = syn.punct },
  -- @punctuation.bracket                        ; brackets (e.g. `()` / `{}` / `[]`)
  ["@punctuation.bracket"] = { fg = syn.punct },
  -- ["@punctuation.special"] = {
  --   fg = palette.carpYellow,
  -- },
  ["@constant"] = { link = "@variable" },
  ["@tag.delimiter"] = {
    fg = syn.punct,
  },
  ["@operator"] = {
    fg = palette.carpYellow,
  },
  ["@punctuation.special"] = {
    -- fg = palette.carpYellow,
    fg = syn.punct,
  },

  -- zsh
  ["zshRepeat"] = {
    link = "Keyword",
  },

  -- jsx

  -- ui
  Search = { fg = palette.fujiWhite, bg = palette.waveBlue2 },
  Visual = { bg = palette.waveBlue1 },
  LineNr = { bg = M.base_16.base00 },

  -- diag
  --

  DiagnosticOk = { fg = diag.ok },
  DiagnosticError = { fg = diag.error },
  DiagnosticWarn = { fg = diag.warning },
  DiagnosticInfo = { fg = diag.info },
  DiagnosticHint = { fg = diag.hint },

  -- PLUGINS

  CmpItemKindField = { link = "@property" },
  CmpItemKindProperty = { link = "@property" },
  CmpItemKindIdentifier = { fg = syn.identifier },
  CmpItemKindTypeParameter = { link = "@type" },
  CmpItemKindVariable = { link = "@variable" },

  -- indentline
  IndentBlanklineContextStart = { bg = "NONE" },

  -- remove colors

  -- TblineFill = { bg = palette.sumiInk0 },
  -- TbLineFill = { bg = palette.sumiInk0 },
  -- TabLine = { bg = palette.sumiInk0 },
  TabLine = { bg = palette.sumiInk0, fg = palette.sumiInk4 },
  -- TblineBufOn = { bg = palette.sumiInk3, fg = palette.fujiWhite },

  -- telescope
  TelescopePromptTitle = { bg = "nord_blue" },
  TelescopePromptPrefix = { fg = "nord_blue" },

  -- tabline
  -- TblineFill = { bg = palette.sumiInk0 },
  -- TablineFill = { bg = palette.sumiInk0 },
  -- TabLine = { bg = palette.sumiInk0 },
  -- TbLineBufOn = { bg = palette.sumiInk4, fg = palette.fujiWhite, italic = true, bold = true },
  -- TbLineBufOff = { bg = palette.sumiInk2, fg = base_30.grey_fg },
  -- TbLineBufOff = { bg = "#17171e", fg = base_30.grey_fg },
  -- TbLineBufOffClose = { link = "TbLineBufOff" },
  -- TbLineBufOnClose = { link = "TbLineBufOn" },
  -- TbLineBufOnModified = { link = "TbLineBufOn" },
  -- TbLineBufOffModified = { link = "TbLineBufOff" },

  --nvim tree
  NvimTreeEmptyFolderName = { fg = base_30.folder_bg },
  NvimTreeEndOfBuffer = { fg = base_30.black },
  NvimTreeFolderIcon = { fg = base_30.folder_bg },
  NvimTreeFolderName = { fg = base_30.folder_bg },
  NvimTreeFolderArrowOpen = { fg = base_30.folder_bg },
  NvimTreeFolderArrowClosed = { fg = base_30.grey_fg },
  NvimTreeGitDirty = { fg = base_30.sun },
  NvimTreeIndentMarker = { fg = base_30.grey_fg },
  NvimTreeNormal = { bg = base_30.black },
  NvimTreeNormalNC = { bg = base_30.black },
  NvimTreeOpenedFolderName = { fg = base_30.folder_bg },
  NvimTreeGitIgnored = { fg = base_30.light_grey },

  NvimTreeWinSeparator = {
    link = "WinSeparator",
  },

  NvimTreeWindowPicker = {
    fg = base_30.red,
    bg = base_30.black2,
  },

  NvimTreeCursorLine = {
    bg = palette.sumiInk4,
  },

  NvimTreeGitNew = {
    fg = palette.springGreen,
  },

  NvimTreeGitDeleted = {
    fg = base_30.red,
  },

  NvimTreeSpecialFile = {
    fg = palette.carpYellow,
    bold = true,
  },

  NvimTreeRootFolder = {
    fg = base_30.purple,
    bold = true,
  },
}

---@type HLTable
M.add = {
  -- fix Multi Visual tabline
  St_paste_sep = {
    fg = "yellow",
    bg = "lightbg",
  },

  St_paste_icon = {
    fg = "black",
    bg = "yellow",
  },

  St_paste_text = {
    fg = "white",
    bg = "lightbg",
  },

  ["@type.qualifier"] = {
    fg = palette.oniViolet,
  },

  ["@lsp.typemod.variable.defaultLibrary"] = {
    link = "@variable.builtin",
    -- link = "Variable",
  },

  ["@constant.typescript"] = {
    link = "Variable",
  },

  ["@lsp.typemod.function.declaration.lua"] = {
    link = "@function",
  },

  ["@lsp.type.property.lua"] = {
    fg = palette.carpYellow,
  },

  ["@lsp.mod.declaration"] = {
    fg = palette.carpYellow,
  },
  ["@lsp.type.namespace"] = {
    link = "@variable",
  },
  ["@keyword.coroutine"] = {
    bold = true,
    fg = syn.keyword,
  },

  ["@lsp.typemod.parameter.declaration"] = {
    fg = palette.carpYellow,
  },

  -- ["@lsp.typemod.variable.readonly"] = {
  --   fg = palette.surimiOrange,
  -- },
  ["@lsp.mod.readonly"] = {
    fg = palette.surimiOrange,
  },
  ["@lsp.typemod.function.readonly"] = {
    link = "@function",
  },
  ["@lsp.typemod.variable.local"] = {
    link = "@variable",
  },
  ["@lsp.typemod.property.readonly"] = {
    link = "@property",
  },
  ["@lsp.typemod.variable.declaration"] = {
    link = "@variable",
  },
  ["@lsp.typemod.member.declaration"] = {
    link = "@function",
  },
  ["@lsp.typemod.property.declaration"] = {
    link = "@property",
  },

  -- terraform
  ["@lsp.type.string.terraform"] = {
    link = "@string",
  },
  ["@lsp.type.variable.terraform"] = {
    fg = base_30.white,
  },
  ["@lsp.type.keyword.terraform"] = {
    link = "@keyword",
  },
  ["@lsp.type.enumMember.terraform"] = {
    -- link = "@type",
    fg = palette.fujiWhite,
    -- fg = palette.surimiOrange,
  },

  -- react
  ["@constructor.tsx"] = {
    fg = syn.type,
  },
  ["@none.tsx"] = {
    -- fg = palette.carpYellow,
    -- fg = syn.punct,
    fg = palette.oniViolet,
  },

  DiagnosticUnnecessary = { fg = palette.boatYellow1, italic = false },

  DiagnosticUnderlineError = { undercurl = true, sp = diag.error },
  DiagnosticUnderlineWarn = { undercurl = true, sp = diag.warning },
  DiagnosticUnderlineInfo = { undercurl = true, sp = diag.info },
  DiagnosticUnderlineHint = { undercurl = true, sp = diag.hint },
  -- -- ["zshRepeat"] = { link = "Keyword" },
  ["zshSubstDelim"] = { fg = syn.punct },
  ["zshBrackets"] = { fg = syn.punct },
  ["zshFunction"] = { link = "@function" },
  -- ["zshSubstQuoted"] = { link = "Normal" },
  -- ["zshDeref"] = { link = "Variable" },

  -- NvimTreeIndentMarker = { fg = palette.boatYellow1 },
  BufferLineBackground = {
    bg = palette.sumiInk5,
  },

  WinBarBg = {
    bg = gutter_bg,
    fg = gutter_bg,
  },

  WinBar = {
    bg = gutter_bg,
    fg = base_30.white,
  },

  WinbarPath = {
    bg = gutter_bg,
    fg = palette.sumiInk6,
  },
  -- tabufline
  -- hl(0, "TbLineBufOn", { bg = "#1F1F28", fg = "#C8C3A6", italic = true, bold = true })
  TablineFill = { bg = palette.sumiInk0, fg = palette.sumiInk4 },
  TabLine = { bg = palette.sumiInk0, fg = palette.sumiInk4 },
  TabLineSel = { bg = palette.sumiInk4 },
  -- TablineFill = { bg = palette.sumiInk0 },
  -- TabLine = { bg = palette.sumiInk0 },
  -- TabLineSel = { bg = palette.sumiInk4, fg = palette.fujiWhite, italic = true, bold = true },
  -- TbLineBufOff = { bg = palette.sumiInk2, fg = base_30.grey_fg },
  -- TabLineOff = {},
}

M.load_custom_highlights = function()
  -- manual syntax highlighting
  local hl = vim.api.nvim_set_hl
  hl(0, "StatusColumn", { bg = gutter_bg, fg = palette.sumiInk6 })
  hl(0, "SignColumn", { bg = gutter_bg, fg = palette.sumiInk6 })
  hl(0, "StatusColumnNr", { bg = gutter_bg, fg = palette.surimiOrange })
  hl(0, "StatusColumnRight", { fg = gutter_bg, bg = palette.sumiInk3 })
  --
  hl(0, "GitSignsAdd", { bg = palette.sumiInk3, fg = palette.springGreen })
  hl(0, "GitSignsDelete", { bg = palette.sumiInk3, fg = palette.waveRed })
  hl(0, "GitSignsChange", { bg = palette.sumiInk3, fg = palette.autumnYellow })
  hl(0, "GitSignsUntracked", { bg = palette.sumiInk3, fg = palette.springGreen })

  hl(0, "DiagnosticSignHint", { fg = diag.hint, bg = gutter_bg })
  hl(0, "DiagnosticSignError", { fg = diag.error, bg = gutter_bg })
  hl(0, "DiagnosticSignWarn", { fg = diag.warning, bg = gutter_bg })
  hl(0, "DiagnosticSignInfo", { fg = diag.info, bg = gutter_bg })

  hl(0, "DapSignColumn", { bg = gutter_bg, fg = palette.fujiWhite })

  hl(0, "TabLineSel", { bg = palette.sumiInk4, fg = palette.fujiWhite, italic = true, bold = true })
  hl(0, "TabLineSelIcon", { bg = palette.sumiInk4, fg = "#7fb4ca" })
  hl(0, "TabLineSelSep", { bg = palette.sumiInk4, fg = palette.fujiWhite, italic = true })

  hl(0, "TabLineOff", { bg = palette.sumiInk3, fg = base_30.grey_fg })
  hl(0, "TabLineOffIcon", { bg = palette.sumiInk3, fg = "#7fb4ca" })
  hl(0, "TabLineOffSep", { bg = palette.sumiInk3, fg = palette.sumiInk5 })

  hl(0, "CodeActionNormal", { fg = palette.fujiWhite })
  hl(0, "CodeActionShortcut", { fg = palette.carpYellow })
  -- hl(0, "CursorLineNr", { bg = gutter_bg, fg = palette.surimiOrange })
  -- hl(0, "TabLine", { bg = palette.sumiInk2, fg = palette.sumiInk4 })
  -- hl(0, "DiagnosticSignInfo", { fg = diag.info, bg = gutter_bg })
end

M.palette = palette
return M
