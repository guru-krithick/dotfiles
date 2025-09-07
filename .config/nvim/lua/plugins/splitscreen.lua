return {
	"mrjones2014/smart-splits.nvim",
	lazy = false, -- Load this plugin on startup for seamless integration
	keys = {
		-- Keys for MOVING between splits
		{
			"<C-h>",
			function()
				require("smart-splits").move_left()
			end,
			desc = "Move to left split",
		},
		{
			"<C-j>",
			function()
				require("smart-splits").move_down()
			end,
			desc = "Move to down split",
		},
		{
			"<C-k>",
			function()
				require("smart-splits").move_up()
			end,
			desc = "Move to up split",
		},
		{
			"<C-l>",
			function()
				require("smart-splits").move_right()
			end,
			desc = "Move to right split",
		},

		-- Keys for RESIZING splits
		{
			"<C-S-h>",
			function()
				require("smart-splits").resize_left()
			end,
			desc = "Resize split left",
		},
		{
			"<C-S-j>",
			function()
				require("smart-splits").resize_down()
			end,
			desc = "Resize split down",
		},
		{
			"<C-S-k>",
			function()
				require("smart-splits").resize_up()
			end,
			desc = "Resize split up",
		},
		{
			"<C-S-l>",
			function()
				require("smart-splits").resize_right()
			end,
			desc = "Resize split right",
		},
	},
}
