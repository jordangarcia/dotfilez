local cmp = require("cmp")

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

local options = {
	-- completion = {
	--   completeopt = "menu,menuone",
	-- },

	window = {
		completion = {
			side_padding = 1,
			winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:PmenuSel",
			scrollbar = false,
			-- border = border "CmpBorder",
		},
		documentation = {
			border = border("CmpDocBorder"),
			winhighlight = "Normal:CmpDoc",
		},
	},

	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},

	-- formatting = {
	-- 	format = function()
	-- 		require("lspkind").cmp_format({
	-- 			maxwidth = 50,
	-- 		})
	-- 	end,
	-- },

	mapping = {

		["<C-k>"] = cmp.mapping.select_prev_item(),
		["<C-j>"] = cmp.mapping.select_next_item(),
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<C-y>"] = cmp.mapping.confirm({
			behavior = cmp.ConfirmBehavior.Insert,
			select = true,
		}),
	},

	sources = {
		{ name = "nvim_lsp", keyword_length = 3 },
		{ name = "luasnip" },
		{ name = "buffer", keyword_length = 5 },
		-- { name = "nvim_lua" },
		-- { name = "path" },
	},
}

vim.cmd([[
  set completeopt=menuone,noinsert,noselect
  highlight! default link CmpItemKind CmpItemMenuDefault
]])

return options
