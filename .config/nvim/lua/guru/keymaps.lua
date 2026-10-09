local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" })

-- Splits
map("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

map("n", "<C-Left>", "<C-w>h", { desc = "Move to the left split" })
map("n", "<C-Right>", "<C-w>l", { desc = "Move to the right split" })
map("n", "<C-Up>", "<C-w>k", { desc = "Move to the upper split" })
map("n", "<C-Down>", "<C-w>j", { desc = "Move to the down split" })

-- Tabs
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

-- Visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selected lines down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selected lines up" })
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

map("n", "J", "mzJ`z", { desc = "Join lines" })

-- Keep the cursor centred while moving
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, cursor centred" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, cursor centred" })
map("n", "n", "nzzzv", { desc = "Next search result centred" })
map("n", "N", "Nzzzv", { desc = "Previous search result centred" })

map("x", "<leader>p", [["_dP]], { desc = "Paste without clobbering the register" })
map({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })

-- Lives under <leader>r alongside the LSP rename (<leader>rn, set on LspAttach).
-- Previously bound to <leader>s, which collided with the <leader>s split prefix
-- and forced a 'timeoutlen' wait on every split keybind.
map(
	"n",
	"<leader>rs",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Search and replace word under cursor" }
)

map("n", "<leader>X", function()
	vim.system({ "chmod", "+x", vim.api.nvim_buf_get_name(0) }):wait()
end, { desc = "Make file executable" })

map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix item" })
map("n", "[q", "<cmd>cprevious<cr>", { desc = "Previous quickfix item" })
map("n", "<leader>cl", function()
	if vim.fn.getqflist({ winid = 0 }).winid == 0 then
		vim.cmd.copen()
	else
		vim.cmd.cclose()
	end
end, { desc = "Toggle quickfix" })
