-- nvim-lspconfig ships one file per server under `lsp/`, which Neovim finds
-- automatically and merges these overrides into. Only genuine deviations from
-- upstream belong here -- never cmd/filetypes/root_markers.
-- Keymaps live in the LspAttach autocmd in guru/autocmds.lua.

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"saghen/blink.cmp",
		"b0o/schemastore.nvim",
	},
	config = function()
		vim.diagnostic.config({
			virtual_text = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "✘",
					[vim.diagnostic.severity.WARN] = "▲",
					[vim.diagnostic.severity.HINT] = "⚑",
					[vim.diagnostic.severity.INFO] = "●",
				},
			},
			underline = true,
			severity_sort = true,
			float = { source = true },
			update_in_insert = false,
		})

		-- Applies to every server, including ones mason enables automatically.
		vim.lsp.config("*", {
			capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		})

		vim.lsp.config("rust_analyzer", {
			settings = {
				["rust-analyzer"] = {
					check = { command = "clippy" },
					cargo = { allFeatures = true },
				},
			},
		})

		vim.lsp.config("ts_ls", {
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
					},
				},
			},
		})

		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
		})

		vim.lsp.config("clangd", {
			cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
		})

		vim.lsp.config("eslint", {
			settings = { workingDirectories = { mode = "auto" } },
		})

		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		})

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemaStore = { enable = false, url = "" },
					schemas = require("schemastore").yaml.schemas(),
				},
			},
		})

		-- Svelte needs telling when TS/JS files it tracks change on disk.
		vim.lsp.config("svelte", {
			on_attach = function(client)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					callback = function(ctx)
						client:notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_fname(ctx.match) })
					end,
				})
			end,
		})

		-- mason's automatic_enable covers the rest; rust_analyzer comes from
		-- rustup, so it needs enabling by hand.
		vim.lsp.enable("rust_analyzer")
	end,
}
