local g = vim.g
local keymap = vim.keymap

g.mapleader = " "

vim.keymap.set({ "n", "i", "v" }, "<Up>", "<Nop>")
vim.keymap.set({ "n", "i", "v" }, "<Down>", "<Nop>")
vim.keymap.set({ "n", "i", "v" }, "<Left>", "<Nop>")
vim.keymap.set({ "n", "i", "v" }, "<Right>", "<Nop>")

-- Better escape
keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Quick save and quit
keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

-- Clear search highlights
keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear highlights" })

keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<C-Left>", "<C-w>h", { desc = "Move to the left split" })
keymap.set("n", "<C-Right>", "<C-w>l", { desc = "Move to the right split" })
keymap.set("n", "<C-Up>", "<C-w>k", { desc = "Move to the upper split" })
keymap.set("n", "<C-Down>", "<C-w>j", { desc = "Move to the down split" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" })

keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move the selected line bellow" })
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move the selected line above" })

-- Better indenting in visual mode (stay in visual mode)
keymap.set("v", "<", "<gv", { desc = "Indent left" })
keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- Join lines without moving cursor
keymap.set("n", "J", "mzJ`z", { desc = "Join lines" })

keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Move half page down and keep the cursor centered" })
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Move half page up and keep the cursor centered" })
keymap.set("n", "n", "nzzzv", { desc = "Next search result centered" })
keymap.set("n", "N", "Nzzzv", { desc = "Previous search result centered" })

keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without copying the contents to the clipboard" })
keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system's clipboard" })

keymap.set(
	"n",
	"<leader>s",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Global search and replace the word" }
)
keymap.set("n", "<leader>X", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make a file executable" })

-- Tmux Sessionizer (only works inside tmux)
keymap.set(
	"n",
	"<C-f>",
	"<cmd>silent !tmux neww ~/.config/tmux/scripts/tmux-sessionizer.sh<CR>",
	{ desc = "Open tmux sessionizer" }
)
keymap.set(
	"n",
	"<M-h>",
	"<cmd>silent !tmux neww ~/.config/tmux/scripts/tmux-sessionizer.sh -s 0 --vsplit<CR>",
	{ desc = "Sessionizer vsplit" }
)
keymap.set(
	"n",
	"<M-H>",
	"<cmd>silent !tmux neww ~/.config/tmux/scripts/tmux-sessionizer.sh -s 0<CR>",
	{ desc = "Sessionizer new window" }
)
