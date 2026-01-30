return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-nvim-lsp-signature-help",
		"onsails/lspkind.nvim",
	},

	config = function()
		local cmp = require("cmp")
		local lspkind = require("lspkind")

		cmp.setup({
			preselect = cmp.PreselectMode.None,
			completion = {
				completeopt = "menu,menuone,noselect",
				keyword_length = 2,
			},

			snippet = {
				-- Disable snippets completely
				expand = function() end,
			},

			window = {
				completion = cmp.config.window.bordered(),
				documentation = cmp.config.window.bordered(),
			},

			-- Filter out snippets and limit results
			matching = {
				disallow_fuzzy_matching = false,
				disallow_partial_matching = false,
				disallow_prefix_unmatching = true,
			},

			mapping = cmp.mapping.preset.insert({
				["<C-n>"] = cmp.mapping.select_next_item(),
				["<C-p>"] = cmp.mapping.select_prev_item(),
				["<C-y>"] = cmp.mapping.confirm({ select = true }),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-d>"] = cmp.mapping.scroll_docs(4),
				["<C-e>"] = cmp.mapping.abort(),

				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					else
						fallback()
					end
				end, { "i", "s" }),

				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					else
						fallback()
					end
				end, { "i", "s" }),
			}),

			sources = cmp.config.sources({
				{
					name = "nvim_lsp",
					max_item_count = 10,
					entry_filter = function(entry)
						-- Filter out snippets from LSP
						return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Snippet"
					end,
				},
				{ name = "nvim_lsp_signature_help" },
				{ name = "path", max_item_count = 5 },
			}, {
				{ name = "buffer", keyword_length = 4, max_item_count = 5 },
			}),

			formatting = {
				format = lspkind.cmp_format({
					mode = "symbol_text",
					maxwidth = 50,
					ellipsis_char = "...",
					menu = {
						nvim_lsp = "[LSP]",
						buffer = "[Buf]",
						path = "[Path]",
					},
				}),
			},

			experimental = {
				ghost_text = false,
			},
		})
	end,
}
