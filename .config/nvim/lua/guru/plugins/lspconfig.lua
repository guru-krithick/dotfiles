return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
    },

    init = function()
        ---------------------------------------------------
        -- DIAGNOSTICS CONFIGURATION (LOADED IMMEDIATELY)
        ---------------------------------------------------
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

        ---------------------------------------------------
        -- HOVER CONFIGURATION
        ---------------------------------------------------
        vim.lsp.handlers["textDocument/hover"] =
            vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded", max_width = 80 })
    end,

    config = function()
        ---------------------------------------------------
        -- CAPABILITIES (NO SNIPPETS)
        ---------------------------------------------------
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.completion.completionItem.snippetSupport = false

        ---------------------------------------------------
        -- ON_ATTACH FOR ALL SERVERS
        ---------------------------------------------------
        local function on_attach(_, bufnr)
            local opts = { buffer = bufnr, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
        end

        ---------------------------------------------------
        -- NEW NEOVIM 0.11 vim.lsp.config() API
        ---------------------------------------------------

        -- LUA
        vim.lsp.config("lua_ls", {
            cmd = { "lua-language-server" },
            filetypes = { "lua" },
            root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml", ".git" },
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

        -- RUST
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

        -- TYPESCRIPT
        vim.lsp.config("ts_ls", {
            cmd = { "typescript-language-server", "--stdio" },
            filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
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

        -- SVELTE
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

        -- PYTHON
        vim.lsp.config("pyright", {
            cmd = { "pyright-langserver", "--stdio" },
            filetypes = { "python" },
            root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
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

        -- C/C++
        vim.lsp.config("clangd", {
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=iwyu",
            },
            filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
            root_markers = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac", ".git" },
            capabilities = capabilities,
            on_attach = on_attach,
        })

        ---------------------------------------------------
        -- GENERIC SERVERS
        ---------------------------------------------------
        local basic_servers = {
            { name = "html",    cmd = { "vscode-html-language-server", "--stdio" },         filetypes = { "html" } },
            { name = "cssls",   cmd = { "vscode-css-language-server", "--stdio" },          filetypes = { "css", "scss", "less" } },
            { name = "jsonls",  cmd = { "vscode-json-language-server", "--stdio" },         filetypes = { "json", "jsonc" } },
            { name = "yamlls",  cmd = { "yaml-language-server", "--stdio" },                filetypes = { "yaml", "yaml.docker-compose" } },
            { name = "bashls",  cmd = { "bash-language-server", "start" },                  filetypes = { "sh" } },
            { name = "graphql", cmd = { "graphql-lsp", "server", "-m", "stream" },          filetypes = { "graphql", "typescriptreact", "javascriptreact" } },
            { name = "sqlls",   cmd = { "sql-language-server", "up", "--method", "stdio" }, filetypes = { "sql", "mysql" } },
        }

        for _, server in ipairs(basic_servers) do
            vim.lsp.config(server.name, {
                cmd = server.cmd,
                filetypes = server.filetypes,
                capabilities = capabilities,
                on_attach = on_attach,
            })
        end

        ---------------------------------------------------
        -- ENABLE LSP SERVERS
        ---------------------------------------------------
        vim.lsp.enable({
            "lua_ls",
            "rust_analyzer",
            "ts_ls",
            "svelte",
            "pyright",
            "clangd",
            "html",
            "cssls",
            "jsonls",
            "yamlls",
            "bashls",
            "graphql",
            "sqlls",
        })
    end,
}
