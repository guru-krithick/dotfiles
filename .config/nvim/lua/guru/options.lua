local o = vim.o

-- Must be set before lazy.nvim parses plugin `keys` specs.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

o.number = true
o.relativenumber = true

o.tabstop = 4
o.shiftwidth = 4
o.expandtab = true
o.autoindent = true
o.smartindent = true

o.wrap = false

o.swapfile = false
o.backup = false
o.undofile = true
o.undodir = vim.fn.stdpath("state") .. "/undo"

o.hlsearch = false
o.incsearch = true
o.ignorecase = true
o.smartcase = true

o.cursorline = true
o.signcolumn = "yes"

o.scrolloff = 8
o.sidescrolloff = 8
o.updatetime = 50
vim.opt.isfname:append("@-@")
vim.opt.iskeyword:append("-")

o.backspace = "indent,eol,start"
vim.opt.clipboard:append("unnamedplus")

o.splitright = true
o.splitbelow = true

o.showmode = false
o.pumheight = 10
o.inccommand = "split"
o.confirm = true

-- Single source of truth for float borders. Replaces the deprecated
-- `vim.lsp.with(handlers.hover, { border = ... })` pattern removed in 0.12.
o.winborder = "rounded"
