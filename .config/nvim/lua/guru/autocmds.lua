local augroup = function(name)
	return vim.api.nvim_create_augroup("guru_" .. name, { clear = true })
end

-- Treesitter highlight and indent. The `main` branch dropped its highlight and
-- indent modules, so enabling them per buffer is the config's job.
-- `language.add()` returns false for uninstalled parsers, keeping unknown
-- filetypes silent rather than throwing.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("treesitter"),
	callback = function(args)
		local ft = vim.bo[args.buf].filetype
		if ft == "" then
			return
		end

		local lang = vim.treesitter.language.get_lang(ft)
		if not lang then
			return
		end

		local ok, added = pcall(vim.treesitter.language.add, lang)
		if not ok or not added then
			return
		end

		pcall(vim.treesitter.start, args.buf, lang)
		-- Experimental upstream.
		pcall(function()
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end)
	end,
})

-- LSP keymaps, set once for every server rather than per vim.lsp.config() call.
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(event)
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = "LSP: " .. desc })
		end

		map("n", "gd", vim.lsp.buf.definition, "Go to definition")
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
		map("n", "gr", vim.lsp.buf.references, "Go to references")
		map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
		map("n", "K", vim.lsp.buf.hover, "Hover documentation")
		map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
		map("n", "<leader>D", vim.lsp.buf.type_definition, "Type definition")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		map("n", "<leader>d", vim.diagnostic.open_float, "Show diagnostic")

		-- goto_prev/goto_next were deprecated in 0.11.
		map("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Previous diagnostic")
		map("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Next diagnostic")

		local client = vim.lsp.get_client_by_id(event.data.client_id)
		if client and client:supports_method("textDocument/documentHighlight") then
			local hl_group = augroup("lsp_highlight_" .. event.buf)
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = hl_group,
				buffer = event.buf,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				group = hl_group,
				buffer = event.buf,
				callback = vim.lsp.buf.clear_references,
			})
		end
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("yank_highlight"),
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

-- Re-applied per colorscheme load; setting it once at startup got wiped on
-- every theme reload.
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup("highlights"),
	callback = function()
		vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#5C5C5C", bg = "NONE" })
	end,
})

-- Restore the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_position"),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
