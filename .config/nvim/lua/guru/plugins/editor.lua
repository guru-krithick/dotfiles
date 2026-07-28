return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				search = { enabled = true },
				char = { jump_labels = true },
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
				-- Not mapped in visual mode; nvim-surround owns visual `S`.
				"S",
				mode = { "n", "o" },
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
		"kylechui/nvim-surround",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			aliases = {
				["a"] = ">",
				["b"] = ")",
				["B"] = "}",
				["r"] = "]",
				["q"] = { '"', "'", "`" },
			},
			highlight = { duration = 200 },
			move_cursor = "begin",
		},
	},

	-- Replaces nvim-autopairs, which only existed to hook nvim-cmp.
	{
		"echasnovski/mini.pairs",
		event = "InsertEnter",
		opts = {},
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
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			settings = { save_on_toggle = true },
		},
		config = function(_, opts)
			require("harpoon"):setup(opts)
		end,
		keys = function()
			-- All under <leader>h. It used to be both a which-key group and a
			-- standalone binding, which forced a 'timeoutlen' wait.
			local keys = {
				{
					"<leader>ha",
					function()
						require("harpoon"):list():add()
					end,
					desc = "Harpoon add file",
				},
				{
					"<leader>hh",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "Harpoon quick menu",
				},
			}

			for i = 1, 9 do
				table.insert(keys, {
					"<leader>" .. i,
					function()
						require("harpoon"):list():select(i)
					end,
					desc = "Harpoon to file " .. i,
				})
			end
			return keys
		end,
	},

	{
		"mbbill/undotree",
		cmd = { "UndotreeToggle", "UndotreeShow" },
		keys = {
			{ "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle undotree" },
		},
	},

	{
		"christoomey/vim-tmux-navigator",
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
}
