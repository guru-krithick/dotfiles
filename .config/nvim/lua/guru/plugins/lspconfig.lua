return {
	"neovim/nvim-lspconfig",
	event = { "FileType" },
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/nvim-cmp",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"b0o/schemastore.nvim",
	},

	init = function()
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
			float = { border = "rounded", source = true },
			update_in_insert = false,
		})

		vim.lsp.handlers["textDocument/hover"] =
			vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded", max_width = 80 })
	end,

	config = function()
		local capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities.textDocument.completion.completionItem.snippetSupport = false

		local function on_attach(_, bufnr)
			local opts = function(desc)
				return { buffer = bufnr, silent = true, desc = desc }
			end
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts("Go to definition"))
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts("Go to declaration"))
			vim.keymap.set("n", "gr", vim.lsp.buf.references, opts("Go to references"))
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts("Go to implementation"))
			vim.keymap.set("n", "K", vim.lsp.buf.hover, opts("Hover documentation"))
			vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts("Signature help"))
			vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts("Type definition"))
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts("Code action"))
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts("Rename symbol"))
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts("Previous diagnostic"))
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts("Next diagnostic"))
			vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts("Show diagnostic"))
		end

		vim.lsp.config("lua_ls", {
			cmd = { "lua-language-server" },
			filetypes = { "lua" },
			root_markers = {
				".luarc.json",
				".luarc.jsonc",
				".luacheckrc",
				".stylua.toml",
				"stylua.toml",
				"selene.toml",
				"selene.yml",
				".git",
			},
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		})

		vim.lsp.config("rust_analyzer", {
			cmd = { "rust-analyzer" },
			filetypes = { "rust" },
			root_markers = { "Cargo.toml", "rust-project.json" },
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				["rust-analyzer"] = {
					checkOnSave = { command = "clippy" },
					cargo = { allFeatures = true },
				},
			},
		})

		vim.lsp.config("ts_ls", {
			cmd = { "typescript-language-server", "--stdio" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
			},
			root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
					},
				},
			},
		})

		vim.lsp.config("svelte", {
			cmd = { "svelteserver", "--stdio" },
			filetypes = { "svelte" },
			root_markers = { "package.json", ".git" },
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				vim.api.nvim_create_autocmd("BufWritePost", {
					pattern = { "*.js", "*.ts" },
					callback = function(ctx)
						client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
					end,
				})
			end,
		})

		vim.lsp.config("pyright", {
			cmd = { "pyright-langserver", "--stdio" },
			filetypes = { "python" },
			root_markers = {
				"pyproject.toml",
				"setup.py",
				"setup.cfg",
				"requirements.txt",
				"Pipfile",
				"pyrightconfig.json",
				".git",
			},
			capabilities = capabilities,
			on_attach = on_attach,
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
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--fallback-style=llvm",
				"--all-scopes-completion",
				"--pch-storage=memory",
			},
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
			root_markers = {
				".clangd",
				".clang-tidy",
				".clang-format",
				"compile_commands.json",
				"compile_flags.txt",
				"configure.ac",
				".git",
			},
			capabilities = capabilities,
			on_attach = function(client, bufnr)
				on_attach(client, bufnr)
				-- Switch between header/source
				vim.keymap.set("n", "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>",
					{ buffer = bufnr, desc = "Switch header/source" })
			end,
		})

		vim.lsp.config("jdtls", {
			cmd = { "jdtls" },
			filetypes = { "java" },
			root_markers = {
				"build.gradle",
				"build.gradle.kts",
				"settings.gradle",
				"settings.gradle.kts",
				"pom.xml",
				".git",
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("tailwindcss", {
			cmd = { "tailwindcss-language-server", "--stdio" },
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"svelte",
			},
			root_markers = {
				"tailwind.config.js",
				"tailwind.config.cjs",
				"tailwind.config.mjs",
				"tailwind.config.ts",
				"postcss.config.js",
				"postcss.config.cjs",
				"postcss.config.mjs",
				"postcss.config.ts",
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("emmet_ls", {
			cmd = { "emmet-ls", "--stdio" },
			filetypes = {
				"html",
				"css",
				"scss",
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"svelte",
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("eslint", {
			cmd = { "vscode-eslint-language-server", "--stdio" },
			filetypes = {
				"javascript",
				"javascriptreact",
				"javascript.jsx",
				"typescript",
				"typescriptreact",
				"typescript.tsx",
				"svelte",
			},
			root_markers = {
				".eslintrc",
				".eslintrc.js",
				".eslintrc.cjs",
				".eslintrc.yaml",
				".eslintrc.yml",
				".eslintrc.json",
				"eslint.config.js",
				"eslint.config.mjs",
				"eslint.config.cjs",
				"package.json",
			},
			capabilities = capabilities,
			on_attach = on_attach,
			settings = {
				workingDirectories = { mode = "auto" },
			},
		})

		vim.lsp.config("ruff", {
			cmd = { "ruff", "server" },
			filetypes = { "python" },
			root_markers = {
				"pyproject.toml",
				"ruff.toml",
				".ruff.toml",
				".git",
			},
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("dockerls", {
			cmd = { "docker-langserver", "--stdio" },
			filetypes = { "dockerfile" },
			root_markers = { "Dockerfile", ".git" },
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("docker_compose_language_service", {
			cmd = { "docker-compose-langserver", "--stdio" },
			filetypes = { "yaml.docker-compose" },
			root_markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml" },
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("taplo", {
			cmd = { "taplo", "lsp", "stdio" },
			filetypes = { "toml" },
			root_markers = { ".taplo.toml", "taplo.toml", ".git" },
			capabilities = capabilities,
			on_attach = on_attach,
		})

		vim.lsp.config("marksman", {
			cmd = { "marksman", "server" },
			filetypes = { "markdown" },
			root_markers = { ".marksman.toml", ".git" },
			capabilities = capabilities,
			on_attach = on_attach,
		})

		local basic_servers = {
			{ name = "html", cmd = { "vscode-html-language-server", "--stdio" }, filetypes = { "html" } },
			{
				name = "cssls",
				cmd = { "vscode-css-language-server", "--stdio" },
				filetypes = { "css", "scss", "less" },
			},
			{
				name = "jsonls",
				cmd = { "vscode-json-language-server", "--stdio" },
				filetypes = { "json", "jsonc" },
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			},
			{
				name = "yamlls",
				cmd = { "yaml-language-server", "--stdio" },
				filetypes = { "yaml", "yaml.docker-compose" },
				settings = {
					yaml = {
						schemaStore = { enable = false, url = "" },
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			},
			{ name = "bashls", cmd = { "bash-language-server", "start" }, filetypes = { "sh", "bash", "zsh" } },
			{
				name = "graphql",
				cmd = { "graphql-lsp", "server", "-m", "stream" },
				filetypes = { "graphql", "typescriptreact", "javascriptreact" },
			},
			{
				name = "sqls",
				cmd = { "sqls" },
				filetypes = { "sql", "mysql", "plsql" },
			},
			{
				name = "prismals",
				cmd = { "prisma-language-server", "--stdio" },
				filetypes = { "prisma" },
			},
			{
				name = "gopls",
				cmd = { "gopls" },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
			},
			{
				name = "nginx_language_server",
				cmd = { "nginx-language-server" },
				filetypes = { "nginx" },
			},
		}

		for _, server in ipairs(basic_servers) do
			vim.lsp.config(server.name, {
				cmd = server.cmd,
				filetypes = server.filetypes,
				settings = server.settings,
				capabilities = capabilities,
				on_attach = on_attach,
			})
		end

		vim.lsp.enable({
			"lua_ls",
			"rust_analyzer",
			"gopls",
			"ts_ls",
			"eslint",
			"tailwindcss",
			"emmet_ls",
			"svelte",
			"graphql",
			"prismals",
			"pyright",
			"ruff",
			"clangd",
			"jdtls",
			"jsonls",
			"yamlls",
			"taplo",
			"marksman",
			"bashls",
			"dockerls",
			"docker_compose_language_service",
			"sqls",
			"nginx_language_server",
			"html",
			"cssls",
		})
	end,
}
