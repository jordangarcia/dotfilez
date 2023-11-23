dofile(vim.g.base46_cache .. "cmp")

-- setup mason
-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

-- local cmp_ui = require("core.utils").load_config().ui.cmp
local cmp_ui = {
  icons = true,
  lspkind_text = true,
  -- style = "default", -- default/flat_light/flat_dark/atom/atom_colored
  style = "flat_dark",
  border_color = "grey_fg", -- only applicable for "default" style, use color names from base30 variables
  selected_item_bg = "colored", -- colored / simple
}

-- todo this should be in custom
local formatting_style = {
  -- default fields order i.e completion word + item.kind + item.kind icons
  fields = { "kind", "abbr", "menu" },

  format = function(_, item)
    local icons = require "nvchad.icons.lspkind"
    local icon = (cmp_ui.icons and icons[item.kind]) or ""

    icon = cmp_ui.lspkind_text and (" " .. icon .. " ") or icon
    -- todo move this into custom
    local kind = cmp_ui.lspkind_text and item.kind or ""
    item.kind = icon
    item.menu = kind

    local MAX = 30

    if #item.abbr > MAX then
      item.abbr = item.abbr:sub(1, MAX - 1) .. " "
    else
      -- pad worMAX to 30 chars
      item.abbr = item.abbr .. string.rep(" ", MAX - #item.abbr)
    end

    return item
  end,
}

local function border(hl_name)
  return {
    { "╭", hl_name },
    { "─", hl_name },
    { "╮", hl_name },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end

---@type LazyPluginSpec[]
return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  keys = { ":", "/" },
  dependencies = {
    {
      -- snippet plugin
      "L3MON4D3/LuaSnip",
      dependencies = "rafamadriz/friendly-snippets",
      opts = { history = true, updateevents = "TextChanged,TextChangedI" },
      config = function(_, opts)
        require("luasnip").config.set_config(opts)

        -- vscode format
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }

        -- snipmate format
        require("luasnip.loaders.from_snipmate").load()
        require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }

        -- lua format
        require("luasnip.loaders.from_lua").load()
        require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }

        vim.api.nvim_create_autocmd("InsertLeave", {
          callback = function()
            if
              require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
              and not require("luasnip").session.jump_active
            then
              require("luasnip").unlink_current()
            end
          end,
        })
      end,
    },

    -- autopairing of (){}[] etc
    {
      -- using lexima right now
      enabled = false,
      "windwp/nvim-autopairs",
      opts = {
        fast_wrap = {},
        disable_filetype = { "TelescopePrompt", "vim" },
      },
      config = function(_, opts)
        require("nvim-autopairs").setup(opts)

        -- setup cmp for autopairs
        local cmp_autopairs = require "nvim-autopairs.completion.cmp"
        require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end,
    },

    -- cmp sources plugins
    {
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
  },
  opts = function()
    local cmp = require "cmp"
    return {
      completion = {
        completeopt = "menu,menuone",
      },

      window = {
        completion = {
          side_padding = 0,
          winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
          scrollbar = false,
        },
        documentation = {
          border = border "CmpDocBorder",
          winhighlight = "Normal:CmpDoc",
        },
      },

      snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      },

      formatting = formatting_style,

      mapping = {

        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.close(),
        ["<CR>"] = cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        },
        ["<Tab>"] = cmp.mapping(function(fallback)
          if require("copilot.suggestion").is_visible() then
            require("copilot.suggestion").accept_line()
          elseif cmp.visible() then
            cmp.select_next_item()
          elseif require("luasnip").expand_or_jumpable() then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
          else
            fallback()
          end
        end, {
          "i",
          "s",
        }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif require("luasnip").jumpable(-1) then
            vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
          else
            fallback()
          end
        end, {
          "i",
          "s",
        }),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
      },
      sorting = {
        comparators = {
          -- copied from cmp-under, but I don't think I need the plugin for this.
          -- I might add some more of my own.
          function(entry1, entry2)
            local _, entry1_under = entry1.completion_item.label:find "^_+"
            local _, entry2_under = entry2.completion_item.label:find "^_+"
            entry1_under = entry1_under or 0
            entry2_under = entry2_under or 0
            if entry1_under > entry2_under then
              return false
            elseif entry1_under < entry2_under then
              return true
            end
          end,
          cmp.config.compare.offset,
          cmp.config.compare.exact,
          cmp.config.compare.score,
          cmp.config.compare.recently_used,
          cmp.config.compare.kind,
        },
      },

      sources = {
        { name = "nvim_lsp", max_item_count = 8, priority = 100 },
        -- { name = "luasnip" },
        -- { name = "buffer", enabled = true, keyword_length = 3, max_item_count = 2 },
        -- {
        --   name = "buffer",
        --   keyword_length = 5,
        --   max_item_count = 2,
        --   priority = 10,
        --   option = {
        --     get_bufnrs = function()
        --       local bufs = {}
        --       for _, win in ipairs(vim.api.nvim_list_wins()) do
        --         bufs[vim.api.nvim_win_get_buf(win)] = true
        --       end
        --       return vim.tbl_keys(bufs)
        --     end,
        --   },
        -- },
        -- { name = "buffer", enabled = true, keyword_length = 2 },
        { name = "nvim_lua", priority = 150 },
        -- { name = "path" , enabled = false}
      },
    }
  end,
  config = function(_, opts)
    local cmp = require "cmp"
    require("cmp").setup(opts)
    require("cmp").setup.filetype({ "gitcommit" }, {
      enabled = false,
    })
    cmp.setup.cmdline({ "/", "?" }, {
      -- require tab to open
      completion = {
        autocomplete = false,
      },
      mapping = vim.tbl_deep_extend("force", cmp.mapping.preset.cmdline(), {
        ["<C-l>"] = {
          c = require("cmp.config.mapping").confirm { select = false },
        },
        ["<C-j>"] = {
          c = function(fallback)
            local cmp = require "cmp"
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
        },
        ["<C-k>"] = {
          c = function(fallback)
            local cmp = require "cmp"
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        },
      }),
      -- mapping = opts.mapping,
      window = { completion = cmp.config.window.bordered { col_offset = 0 } },
      formatting = { fields = { "abbr" } },
      sources = {
        { name = "buffer" },
      },
    })

    cmp.setup.cmdline(":", {
      -- require tab to open
      completion = {
        autocomplete = false,
      },
      mapping = vim.tbl_deep_extend("force", cmp.mapping.preset.cmdline(), {
        ["<C-l>"] = {
          c = require("cmp.config.mapping").confirm { select = false },
        },
        ["<C-j>"] = {
          c = function(fallback)
            local cmp = require "cmp"
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end,
        },
        ["<C-k>"] = {
          c = function(fallback)
            local cmp = require "cmp"
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end,
        },
      }),
      -- mapping = opts.mapping,
      window = { completion = cmp.config.window.bordered { col_offset = 0 } },
      formatting = { fields = { "abbr" } },
      sources = cmp.config.sources({
        { name = "path" },
      }, {
        { name = "cmdline" },
      }),
    })
  end,
}
