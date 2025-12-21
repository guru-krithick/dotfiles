return {
	"leath-dub/snipe.nvim",
	keys = {
		{
			"<leader>'",
			function()
				require("snipe").open_buffer_menu()
			end,
			desc = "Snipe buffer menu",
		},
	},
	opts = {
		ui = {
			open_win_override = {
				border = "rounded",
			},
			text_align = "file-first",
		},
		hints = {
			dictionary = "asfghjklqwertyuiopzxcvbnm",
		},
		navigate = {
			cancel_snipe = "<esc>",
			close_buffer = "D",
			open_vsplit = "V",
			open_split = "H",
		},
		sort = "last",
	},
}
