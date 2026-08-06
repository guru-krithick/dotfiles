-- Replaces nvim-cmp + 4 cmp sources + lspkind with one plugin.
-- Not lazy on InsertEnter: nvim-lspconfig depends on it so capabilities are
-- available before any server starts.

return {
	"saghen/blink.cmp",
	-- v2 requires blink.lib as a separate dependency.
	version = "1.*",
	opts = {
		keymap = {
			preset = "default", -- <C-n>/<C-p> select, <C-y> accept, <C-e> hide, <C-space> docs
			["<Tab>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<C-d>"] = { "scroll_documentation_down", "fallback" },
		},

		-- Neovim 0.12's built-in snippet engine -- no LuaSnip needed.
		snippets = { preset = "default" },

		signature = { enabled = true },

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			ghost_text = { enabled = false },
			menu = { border = "rounded" },
			-- preselect off so the menu opening does not commit to anything;
			-- auto_insert on so <Tab>/<S-Tab> write each item into the buffer
			-- as you cycle. <C-e> undoes the insert and closes the menu.
			list = { selection = { preselect = false, auto_insert = true } },
		},

		appearance = { nerd_font_variant = "mono" },

		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
