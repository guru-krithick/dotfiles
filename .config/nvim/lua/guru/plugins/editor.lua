return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				search = { enabled = false },
				char = { enabled = false },
			},
		},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = "c",
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},

	{
		"stevearc/oil.nvim",
		dependencies = { "echasnovski/mini.icons" },
		lazy = false, -- must claim the netrw hijack before any directory buffer
		keys = {
			{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
			{ "<leader>ee", "<cmd>Oil<cr>", desc = "Open file explorer" },
		},
		opts = {
			default_file_explorer = true,
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
				natural_order = true,
			},
			float = {
				padding = 2,
				max_width = 90,
				max_height = 0,
			},
			keymaps = {
				["g?"] = "actions.show_help",
				["<CR>"] = "actions.select",
				-- select_vsplit/select_split/select_tab folded into actions.select.
				["<C-v>"] = { "actions.select", opts = { vertical = true } },
				["<C-s>"] = { "actions.select", opts = { horizontal = true } },
				["<C-t>"] = { "actions.select", opts = { tab = true } },
				-- Buffer-local, so it shadows the global <C-p> file picker here only.
				["<C-p>"] = "actions.preview",
				["<C-c>"] = "actions.close",
				["q"] = "actions.close",
				["<C-r>"] = "actions.refresh",
				["-"] = "actions.parent",
				["_"] = "actions.open_cwd",
				["`"] = "actions.cd",
				["~"] = "actions.tcd",
				["gs"] = "actions.change_sort",
				["gx"] = "actions.open_external",
				["g."] = "actions.toggle_hidden",
			},
		},
	},

	{
		"christoomey/vim-tmux-navigator",
		init = function()
			vim.g.tmux_navigator_preserve_zoom = 1
		end,
		cmd = {
			"TmuxNavigateLeft",
			"TmuxNavigateDown",
			"TmuxNavigateUp",
			"TmuxNavigateRight",
			"TmuxNavigatePrevious",
		},
		keys = {
			{ "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left (vim/tmux)" },
			{ "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down (vim/tmux)" },
			{ "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up (vim/tmux)" },
			{ "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right (vim/tmux)" },
			{ "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate to previous (vim/tmux)" },
		},
	},

	{
		"nvim-mini/mini.surround",
		event = "VeryLazy",
		opts = {
			-- Keep s/S for Flash and gs for Git status.
			mappings = {
				add = "gza",
				delete = "gzd",
				replace = "gzr",
				find = "gzf",
				find_left = "gzF",
				highlight = "gzh",
				update_n_lines = "gzn",
			},
		},
	},

	{
		"folke/persistence.nvim",
		event = "BufReadPre",
		opts = {},
		keys = {
			{
				"<leader>or",
				function()
					require("persistence").load()
				end,
				desc = "Restore session",
			},
			{
				"<leader>os",
				function()
					require("persistence").select()
				end,
				desc = "Select session",
			},
			{
				"<leader>ol",
				function()
					require("persistence").load({ last = true })
				end,
				desc = "Last session",
			},
			{
				"<leader>od",
				function()
					require("persistence").stop()
				end,
				desc = "Stop saving session",
			},
		},
	},
}
