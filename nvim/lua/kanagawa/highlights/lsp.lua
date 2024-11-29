local M = {}
---@param colors KanagawaColors
---@param config? KanagawaConfig
function M.setup(colors, config)
  config = config or require("kanagawa").config
  local theme = colors.theme
  return {
    -- ["@lsp.type.class"] = { link = "Structure" },
    -- ["@lsp.type.decorator"] = { link = "Function" },
    -- ["@lsp.type.enum"] = { link = "Structure" },
    -- ["@lsp.type.enumMember"] = { link = "Constant" },
    -- ["@lsp.type.function"] = { link = "Function" },
    -- ["@lsp.type.interface"] = { link = "Structure" },
    ["@lsp.type.macro"] = { link = "Macro" },
    ["@lsp.type.method"] = { link = "@function.method" }, -- Function
    ["@lsp.type.namespace"] = { link = "@module" }, -- Structure
    ["@lsp.type.parameter"] = { link = "@variable.parameter" }, -- Identifier

    -- ["@lsp.type.property"] = { link = "Identifier" },
    -- ["@lsp.type.struct"] = { link = "Structure" },
    -- ["@lsp.type.type"] = { link = "Type" },
    -- ["@lsp.type.typeParameter"] = { link = "TypeDef" },
    ["@lsp.type.variable"] = { fg = "none" }, -- Identifier
    ["@lsp.type.comment"] = { fg = "none" }, -- Comment

    ["@lsp.type.const"] = { link = "Constant" },
    ["@lsp.type.comparison"] = { link = "Operator" },
    ["@lsp.type.bitwise"] = { link = "Operator" },
    ["@lsp.type.punctuation"] = { link = "Delimiter" },

    ["@lsp.type.selfParameter"] = { link = "@variable.builtin" },
    -- ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" },
    ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" },
    ["@lsp.type.magicFunction"] = { link = "@function.builtin" },

    -- ["@lsp.mod.readonly"] = { link = "Constant" },
    ["@lsp.mod.declaration"] = { link = "@variable.parameter" },
    ["@lsp.mod.documentation.lua"] = { link = "Comment" },
    ["@lsp.mod.typeHint"] = { link = "Type" },
    -- ["@lsp.mod.defaultLibrary"] = { link = "Special" },
    -- ["@lsp.mod.builtin"] = { link = "Special" },

    ["@lsp.typemod.operator.controlFlow"] = { link = "@keyword.exception" }, -- rust ? operator
    -- ["@lsp.typemod.keyword.documentation"] = { link = "Special" },
    ["@lsp.typemod.macro"] = { link = "Macro" },
    ["@lsp.typemod.method"] = { link = "@function.method" }, -- Function
    ["@lsp.typemod.namespace"] = { link = "@module" }, -- Structure
    ["@lsp.typemod.parameter"] = { link = "@variable.parameter" }, -- Identifier

    ["@lsp.typemod.type"] = { link = "Type" },
    ["@lsp.typemod.interface"] = { link = "Type" },

    ["@lsp.typemod.variable"] = { link = "Variable" },
    ["@lsp.typemod.variable.global"] = { link = "Constant" },
    ["@lsp.typemod.variable.static"] = { link = "Constant" },
    ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },

    ["@lsp.typemod.function.builtin"] = { link = "@function.builtin" },
    ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
    -- ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },

    ["@lsp.typemod.variable.injected"] = { link = "@variable" },

    ["@lsp.typemod.function.readonly"] = { fg = theme.syn.fun, bold = true },
  }
end

return M
--vim: fdm=marker
