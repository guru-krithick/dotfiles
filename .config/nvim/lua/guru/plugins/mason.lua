-- Repos moved from `williamboman/*` to `mason-org/*`. mason-lspconfig 2.0
-- dropped `automatic_installation` for `automatic_enable`, which calls
-- vim.lsp.enable() on installed servers.

return {
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonToolsInstall", "MasonToolsUpdate" },
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			-- stylua ships an --lsp mode and lspconfig has a config for it, so
			-- automatic_enable starts it as a server. conform already runs
			-- stylua as a formatter; two of them fight over the buffer.
			automatic_enable = { exclude = { "stylua" } },
			ensure_installed = {
				"lua_ls",
				"gopls",
				"ts_ls",
				"eslint",
				"tailwindcss",
				"prismals",
				"html",
				"cssls",
				"emmet_ls",
				"svelte",
				"graphql",
				"pyright",
				"ruff",
				"jsonls",
				"yamlls",
				"taplo",
				"marksman",
				"bashls",
				"clangd",
				"jdtls",
				"dockerls",
				"docker_compose_language_service",
				-- rust_analyzer omitted: rustup ships one matched to the toolchain.
			},
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"stylua",
				"prettier",
				"ruff",
				"clang-format",
				"google-java-format",
				"gofumpt",
				"goimports",
				"shfmt",
				"shellcheck",
				"sqlfluff",
			},
			-- Both true meant a network round-trip on every startup.
			-- Run :MasonToolsUpdate by hand instead.
			auto_update = false,
			run_on_start = false,
		},
	},
}
