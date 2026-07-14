-- VS Code-like editing defaults. File-specific indentation can still be changed by
-- an EditorConfig file or an attached language server.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.autowrite = true
opt.clipboard = "unnamedplus"
opt.cmdheight = 0
opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.foldcolumn = "1"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.ignorecase = true
opt.laststatus = 3
opt.mouse = "a"
opt.number = true
opt.pumheight = 12
opt.relativenumber = false
opt.scrolloff = 3
opt.shiftround = true
opt.shortmess:append("I")
opt.shiftwidth = 4
opt.showmode = false
opt.sidescrolloff = 5
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.splitright = true
opt.tabstop = 4
opt.termguicolors = true
opt.timeoutlen = 500
opt.undofile = true
opt.updatetime = 250
opt.virtualedit = "block"
opt.wildmode = "longest:full,full"
opt.wrap = false
