local cmp = require "cmp"

return {

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
  },
  sorting = {
    comparators = {
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
      -- copied from cmp-under, but I don't think I need the plugin for this.
      -- I might add some more of my own.
      cmp.config.compare.kind,
    },
  },
  -- sorting = {
  --   -- TODO: Would be cool to add stuff like "See variable names before method names" in rust, or something like that.
  --   comparators = {
  --     cmp.config.compare.offset,
  --     -- cmp.config.compare.exact,
  --     -- cmp.config.compare.score,
  --     --
  --     -- -- copied from cmp-under, but I don't think I need the plugin for this.
  --     -- -- I might add some more of my own.
  --     -- function(entry1, entry2)
  --     --   local _, entry1_under = entry1.completion_item.label:find "^_+"
  --     --   local _, entry2_under = entry2.completion_item.label:find "^_+"
  --     --   entry1_under = entry1_under or 0
  --     --   entry2_under = entry2_under or 0
  --     --   if entry1_under > entry2_under then
  --     --     return false
  --     --   elseif entry1_under < entry2_under then
  --     --     return true
  --     --   end
  --     -- end,
  --     --
  --     -- cmp.config.compare.kind,
  --     -- cmp.config.compare.sort_text,
  --     -- cmp.config.compare.length,
  --     -- cmp.config.compare.order,
  --   },
  -- },

  -- matching = {
  --   -- disallow_partial_fuzzy_matching = true,
  --   -- disallow_fuzzy_matching = true,
  --   disallow_fuzzy_matching = true,
  --   disallow_fullfuzzy_matching = true,
  --   disallow_partial_fuzzy_matching = true,
  --   disallow_partial_matching = true,
  --   disallow_prefix_unmatching = false,
  -- },

  sources = {
    { name = "nvim_lsp", max_item_count = 5 },
    -- { name = "luasnip", enabled =false},
    -- { name = "buffer", enabled = true, keyword_length = 3, max_item_count = 2 },
    {
      name = "buffer",
      keyword_length = 5,
      max_item_count = 2,
      option = {

        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
      },
    },
    -- { name = "buffer", enabled = true, keyword_length = 2 },
    { name = "nvim_lua" },
    -- { name = "path" , enabled = false}
  },
}
