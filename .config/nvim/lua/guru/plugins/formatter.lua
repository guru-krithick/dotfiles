return {
	"stevearc/conform.nvim",
	event = { "FileType" },
	config = function()
		local conform = require("conform")
		conform.setup({
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
				toml = { "taplo" },
				markdown = { "prettier" },
				xml = { "prettier" },
				lua = { "stylua" },
				python = { "isort", "black" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				cuda = { "clang-format" },
				java = { "google-java-format" },
				prisma = { "prettier" },
				rust = { "rustfmt" },
				go = { "goimports", "gofumpt" },
				gomod = { "gofumpt" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				zsh = { "shfmt" },
				sql = { "sqlfluff" },
				mysql = { "sqlfluff" },
				postgresql = { "sqlfluff" },
				dockerfile = { "prettier" },
				proto = { "clang-format" },
				nix = { "nixfmt" },
				kotlin = { "ktfmt" },
			},
			format_on_save = {
				lsp_fallback = true,
				timeout_ms = 2500,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>cf", function()
			conform.format({
				lsp_fallback = true,
				timeout_ms = 500,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
