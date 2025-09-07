local set = vim.keymap.set

-- Open terminal in a horizontal split with <space>h
set("n", "<leader>h", ":split | terminal<CR>", { noremap = true, silent = true })

-- Open terminal in a vertical split with <space>v
set("n", "<leader>v", ":vsplit | terminal<CR>", { noremap = true, silent = true })

-- Exit terminal mode with <Esc>
set("t", "<Esc>", "<C-\\><C-n>", { noremap = true })
