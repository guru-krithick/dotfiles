return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  cmd = { "Mason", "MasonInstall", "MasonUpdate" },
  keys = {
    { "<leader>m", "<cmd>Mason<cr>", desc = "Mason: Manage packages" },
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")

    mason.setup({
      max_concurrent_installers = 8,
      ui = {
        border = "rounded",
        width = 0.8,
        height = 0.8,
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      ensure_installed = {
        -- Core languages
        "lua_ls",
        "clangd",
        "gopls",
        "rust_analyzer",
        "ts_ls",  -- TypeScript / JavaScript
	"tailwindcss",
	"jdtls",
	"html",
	"cssls",
	"css_variables",
	"cssmodules_ls",
	"markdown_oxide",
        "bashls",
        "pyright",   -- better than pylsp for Python
        "yamlls",
        "jsonls",
      },
      automatic_installation = true,
    })

    mason_tool_installer.setup({
      ensure_installed = {
        -- Formatters
        "stylua",    -- Lua
        "shfmt",     -- Shell
        "black",     -- Python
        "clang-format",
        "prettier",  -- Web
        -- Linters
        "eslint_d",
        "ruff",      -- Python
      },
      run_on_start = true,
      auto_update = true,
    })
  end,
}
