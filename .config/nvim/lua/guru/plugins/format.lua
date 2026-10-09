return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = { "n", "v" },
			desc = "Format file or selection",
		},
	},
	opts = {
		formatters_by_ft = {
			javascript = { "prettier" },
			typescript = { "prettier" },
			javascriptreact = { "prettier" },
			typescriptreact = { "prettier" },
			svelte = { "prettier" },
			css = { "prettier" },
			scss = { "prettier" },
			html = { "prettier" },
			graphql = { "prettier" },
			json = { "prettier" },
			jsonc = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			prisma = { "prettier" },
			toml = { "taplo" },
			lua = { "stylua" },
			python = { "ruff_organize_imports", "ruff_format" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			cuda = { "clang-format" },
			proto = { "clang-format" },
			java = { "google-java-format" },
			rust = { "rustfmt" },
			go = { "goimports", "gofumpt" },
			gomod = { "gofumpt" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			sql = { "sqlfluff" },
			nix = { "nixfmt" },
			kotlin = { "ktfmt" },
		},
		-- `lsp_fallback` is deprecated in favour of `lsp_format`. 500ms instead
		-- of the old 2500ms so slow formatters can't stall a save.
		format_on_save = function(bufnr)
			if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
				return
			end
			return { timeout_ms = 500, lsp_format = "fallback" }
		end,
		default_format_opts = { lsp_format = "fallback" },
	},
	init = function()
		vim.api.nvim_create_user_command("FormatToggle", function(args)
			if args.bang then
				vim.b.disable_autoformat = not vim.b.disable_autoformat
			else
				vim.g.disable_autoformat = not vim.g.disable_autoformat
			end
		end, { bang = true, desc = "Toggle format-on-save (! for buffer only)" })
	end,
}
