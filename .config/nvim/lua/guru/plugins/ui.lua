return {
	-- Replaces nvim-web-devicons; the mock keeps plugins that require the old
	-- module working.
	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		opts = {
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = true,
				disabled_filetypes = { statusline = { "lazy", "mason" } },
			},
			sections = {
				lualine_a = { {
					"mode",
					fmt = function(mode)
						return mode:sub(1, 3)
					end,
				} },
				lualine_b = { "branch" },
				lualine_c = {
					{ "filename", path = 1, symbols = { modified = "●", readonly = "", unnamed = "[new]" } },
				},
				lualine_x = {
					{
						"diff",
						source = function()
							local git = vim.b.gitsigns_status_dict
							if git then
								return { added = git.added, modified = git.changed, removed = git.removed }
							end
						end,
					},
					{ "diagnostics", sources = { "nvim_diagnostic" }, sections = { "error", "warn" } },
				},
				lualine_y = {},
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			extensions = { "lazy", "man", "quickfix", "oil", "fzf" },
		},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			spec = {
				{ "<leader>c", group = "code" },
				{ "<leader>e", group = "explorer" },
				{ "<leader>f", group = "find" },
				{ "<leader>g", group = "git" },
				{ "<leader>o", group = "sessions" },
				{ "gz", group = "surround" },
				{ "<leader>r", group = "rename/replace" },
				{ "<leader>s", group = "split" },
				{ "<leader>t", group = "tabs" },
				{ "g", group = "goto" },
				{ "z", group = "fold/spell" },
				{ "]", group = "next" },
				{ "[", group = "prev" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer local keymaps",
			},
		},
	},
}
