return {
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo comment",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo comment",
			},
		},
	},

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = { focus = true },
		keys = {
			{ "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Workspace diagnostics" },
			{ "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Document diagnostics" },
			{ "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", desc = "Quickfix list" },
			{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Location list" },
			{ "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Todos" },
			{ "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols" },
		},
	},
}
