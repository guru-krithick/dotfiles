-- `main` branch: installs parsers only. Highlight and indent are enabled per
-- buffer by the FileType autocmd in guru/autocmds.lua. `master` is locked
-- upstream and crashes on Neovim 0.12.
-- Requires the tree-sitter CLI on PATH to compile parsers.

local parsers = {
	"bash",
	"c",
	"cpp",
	"css",
	"diff",
	"dockerfile",
	"git_config",
	"gitcommit",
	"gitignore",
	"go",
	"gomod",
	"graphql",
	"html",
	"java",
	"javascript",
	"json", -- jsonc is not a separate parser; it reuses this one
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"nix",
	"python",
	"query",
	"regex",
	"ron",
	"rust",
	"sql",
	"svelte",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
	"yaml",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		priority = 1000,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup({})
			-- Async, and a no-op for parsers already present.
			require("nvim-treesitter").install(parsers)
		end,
	},

	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			opts = {
				enable_close = true,
				enable_rename = true,
				enable_close_on_slash = true,
			},
		},
	},
}
