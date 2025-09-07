local opt = vim.opt -- for concisenes
local g = vim.g
local api = vim.api

--Line Number
opt.relativenumber = true
opt.number = true

--Tabs
opt.expandtab = true
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.autoindent = true

--Line Wrapping
opt.wrap = false

--Search Settings
opt.ignorecase = true
opt.smartcase = true

--Cursor Line
opt.cursorline = true

--Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
api.nvim_set_hl(0, "WinSeparator", { fg = "#5C5C5C", bg = "NONE" })

--Backspace
opt.backspace = "indent,eol,start"

--Clipboard
opt.clipboard:append("unnamedplus")

--Split Windows
opt.splitright = true
opt.splitbelow = true
opt.iskeyword:append("-")

--MapLeader
g.mapleader = " "
