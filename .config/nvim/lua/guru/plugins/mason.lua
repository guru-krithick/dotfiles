return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		require("mason").setup({
			ui = {
				border = "rounded",
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"rust_analyzer",
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
				"sqls",
				"nginx_language_server",
			},
			automatic_installation = true,
		})

		require("mason-tool-installer").setup({
			ensure_installed = {
				"stylua",
				"prettier",
				"eslint_d",
				"black",
				"isort",
				"ruff",
				"debugpy",
				"clang-format",
				"google-java-format",
				"gofumpt",
				"goimports",
				"shfmt",
				"shellcheck",
				"sqlfluff",
				"yamlfmt",
			},
			auto_update = true,
			run_on_start = true,
		})
	end,
}
