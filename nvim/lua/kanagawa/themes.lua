local c = require "kanagawa.lib.color"

--TODO:
--PreProc needs its own color
--parameter and field should be different
---@class SyntaxElements
---@field string ColorSpec
---@field variable ColorSpec
---@field number ColorSpec
---@field constant ColorSpec
---@field boolean ColorSpec
---@field identifier ColorSpec
---@field constructor ColorSpec
---@field parameter ColorSpec
---@field fun ColorSpec
---@field include ColorSpec
---@field statement ColorSpec
---@field keyword ColorSpec
---@field operator ColorSpec
---@field preproc ColorSpec
---@field builtin ColorSpec
---@field type ColorSpec
---@field regex ColorSpec
---@field deprecated ColorSpec
---@field comment ColorSpec
---@field punct ColorSpec
---@field special1 ColorSpec
---@field special2 ColorSpec
---@field special3 ColorSpec

---@class DiagnosticsElements
---@field error ColorSpec
---@field ok ColorSpec
---@field warning ColorSpec
---@field info ColorSpec
---@field hint ColorSpec
---@field unnecessary ColorSpec
--
---@class DiffElements
---@field add ColorSpec
---@field delete ColorSpec
---@field change ColorSpec
---@field text ColorSpec

---@class VCSElements
---@field added ColorSpec
---@field removed ColorSpec
---@field changed ColorSpec

---@class UiElements
---@field fg ColorSpec Default foreground
---@field fg_dim ColorSpec Dimmed foreground
---@field fg_reverse ColorSpec
---@field bg_dim ColorSpec Dimmed background
---@field bg_m3 ColorSpec
---@field bg_m2 ColorSpec
---@field bg_m1 ColorSpec
---@field bg ColorSpec Default background
---@field bg_p1 ColorSpec Lighter background ColorColumn, Folded, Gutter
---@field bg_p2 ColorSpec Lighter background Cursor{Line,Column}, TabLineSel (Selected Items)
---@field bg_gutter ColorSpec {Sign,Fold}Column, LineNr
---@field special ColorSpec SpecialKey
---@field special2 ColorSpec SpecialKey
---@field special3 ColorSpec SpecialKey
---@field nontext ColorSpec LineNr, NonText
---@field whitespace ColorSpec Whitespace
---@field bg_search ColorSpec
---@field bg_visual ColorSpec
---@field pmenu MenuElements
---@field float FloatElements
---@field title ColorSpec

---@class FloatElements
---@field fg ColorSpec
---@field bg ColorSpec
---@field fg_border ColorSpec
---@field bg_border ColorSpec

---@class MenuElements
---@field bg ColorSpec
---@field fg ColorSpec
---@field fg_sel ColorSpec
---@field bg_sel ColorSpec
---@field bg_sbar ColorSpec
---@field bg_thumb ColorSpec

---@class ThemeColors
---@field syn SyntaxElements
---@field diag DiagnosticsElements
---@field vcs VCSElements
---@field diff DiffElements
---@field ui UiElements
---@field term ColorSpec[]

return {
  ---@param palette PaletteColors
  ---@return ThemeColors
  wave = function(palette)
    return {
      ui = {
        fg = palette.fujiWhite,

        -- fg_dim     = palette.oldWhite,
        fg_dim = palette.sumiInk5,
        fg_reverse = palette.waveBlue1,

        bg_dim = palette.sumiInk1,
        bg_gutter = palette.sumiInk4,

        bg_m3 = palette.sumiInk0,
        bg_m2 = palette.sumiInk1,
        bg_m1 = palette.sumiInk2,
        bg = palette.sumiInk3,
        bg_p1 = palette.sumiInk4,
        bg_p2 = palette.sumiInk5,
        bg_p3 = palette.sumiInk6,

        -- NOTE
        special = palette.springBlue,
        special2 = palette.crystalBlue,
        special3 = palette.surimiOrange,
        -- special = palette.springViolet1,
        nontext = palette.sumiInk6,
        whitespace = palette.sumiInk6,

        bg_search = palette.waveBlue2,
        bg_visual = palette.waveBlue1,

        title = palette.crystalBlue,

        pmenu = {
          fg = palette.fujiWhite,
          fg_sel = palette.sumiInk3,
          bg = palette.sumiInk1,
          bg_sel = palette.purple,
          bg_sbar = palette.waveBlue1,
          bg_thumb = palette.purple,
        },
        float = {
          fg = palette.oldWhite,
          bg = palette.sumiInk0,
          fg_border = palette.sumiInk6,
          bg_border = palette.sumiInk0,
        },
      },
      syn = {
        string = palette.springGreen,
        variable = palette.fujiWhite,
        number = palette.sakuraPink,
        -- constant = palette.carpYellow,
        constant = palette.fujiWhite,
        boolean = palette.surimiOrange,
        builtin = palette.waveRed,
        -- constant = palette.surimiOrange,
        include = palette.surimiOrange,
        identifier = palette.carpYellow,
        -- parameter  = "#C3B1B1",
        -- parameter  = "#B1ADC8",
        -- parameter  = "#b8b4d0",
        -- parameter = "none",
        parameter = palette.carpYellow,
        -- parameter = palette.oniViolet2,
        -- parameter = "#d5a4a6",
        -- parameter  = "#C8ADAD",
        -- parameter  = "#d7a8a8",
        constructor = palette.waveAqua1,
        fun = palette.crystalBlue,
        statement = palette.oniViolet,
        keyword = palette.oniViolet,
        operator = palette.boatYellow2,
        preproc = palette.waveRed, --lightBlue? deserves its own color
        type = palette.waveAqua2,
        regex = palette.boatYellow2,
        deprecated = palette.katanaGray,
        comment = palette.sumiInk5,
        -- comment = palette.dragonGray2,
        -- punct = palette.springViolet2,
        punct = palette.dragonGray2,
        special1 = palette.springBlue,
        special2 = palette.waveRed,
        special3 = palette.peachRed,
      },
      vcs = {
        added = palette.autumnGreen,
        removed = palette.autumnRed,
        changed = palette.autumnYellow,
      },
      diff = {
        add = palette.winterGreen,
        delete = palette.winterRed,
        change = palette.winterBlue,
        text = palette.winterYellow,
      },
      diag = {
        ok = palette.springGreen,
        error = palette.samuraiRed,
        warning = palette.roninYellow,
        info = palette.dragonBlue,
        hint = palette.waveAqua1,
        unnecessary = palette.boatYellow1,
      },
      term = {
        palette.sumiInk0, -- black
        palette.autumnRed, -- red
        palette.autumnGreen, -- green
        palette.boatYellow2, -- yellow
        palette.crystalBlue, -- blue
        palette.oniViolet, -- magenta
        palette.waveAqua1, -- cyan
        palette.oldWhite, -- white
        palette.fujiGray, -- bright black
        palette.samuraiRed, -- bright red
        palette.springGreen, -- bright green
        palette.carpYellow, -- bright yellow
        palette.springBlue, -- bright blue
        palette.springViolet1, -- bright magenta
        palette.waveAqua2, -- bright cyan
        palette.fujiWhite, -- bright white
        palette.surimiOrange, -- extended color 1
        palette.peachRed, -- extended color 2
      },
    }
  end,
}
