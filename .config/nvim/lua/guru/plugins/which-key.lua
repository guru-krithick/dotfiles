return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		preset = "helix",
		spec = {
			{ "<leader>f", group = "find/files" },
			{ "<leader>g", group = "git" },
			{ "<leader>h", group = "harpoon/hunks" },
			{ "<leader>s", group = "split" },
			{ "<leader>t", group = "tabs" },
			{ "<leader>x", group = "trouble" },
			{ "<leader>c", group = "code" },
			{ "g", group = "goto" },
			{ "z", group = "fold/spell" },
			{ "]", group = "next" },
			{ "[", group = "prev" },
			{ "<leader>1", hidden = true },
			{ "<leader>2", hidden = true },
			{ "<leader>3", hidden = true },
			{ "<leader>4", hidden = true },
			{ "<leader>5", hidden = true },
			{ "<leader>6", hidden = true },
			{ "<leader>7", hidden = true },
			{ "<leader>8", hidden = true },
			{ "<leader>9", hidden = true },
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Local Keymaps",
		},
	},
}
