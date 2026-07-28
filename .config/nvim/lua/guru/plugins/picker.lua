-- Replaces telescope + telescope-fzf-native. No `make` step; drives the fzf,
-- rg, fd, bat and delta binaries directly.

return {
	"ibhagwan/fzf-lua",
	dependencies = { "echasnovski/mini.icons" },
	cmd = "FzfLua",
	opts = {
		"default",
		files = { hidden = true },
		grep = { hidden = true },
		keymap = {
			builtin = { ["<C-d>"] = "preview-page-down", ["<C-u>"] = "preview-page-up" },
			fzf = {
				["ctrl-d"] = "preview-page-down",
				["ctrl-u"] = "preview-page-up",
				["ctrl-q"] = "select-all+accept", -- to quickfix
			},
		},
	},
	keys = {
		{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
		{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live grep" },
		{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
		{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help tags" },
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
		{ "<leader>fw", "<cmd>FzfLua grep_cword<cr>", desc = "Find word under cursor" },
		{ "<leader>fd", "<cmd>FzfLua diagnostics_workspace<cr>", desc = "Diagnostics" },
		{ "<leader>fs", "<cmd>FzfLua lsp_document_symbols<cr>", desc = "Document symbols" },
		{ "<leader>fR", "<cmd>FzfLua resume<cr>", desc = "Resume last picker" },
		{ "<leader>/", "<cmd>FzfLua blines<cr>", desc = "Fuzzy find in buffer" },
		{ "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git commits" },
		{ "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git status" },
		{
			"<C-p>",
			function()
				-- git_files errors outside a repo.
				if not pcall(require("fzf-lua").git_files) then
					require("fzf-lua").files()
				end
			end,
			desc = "Git files or find files",
		},
	},
}
